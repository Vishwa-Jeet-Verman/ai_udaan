/**
 * Moodle Messaging Service
 *
 * messagingallusers=0 constraint: students cannot message admin via their own token.
 *
 * Solution — send TWO clean messages via admin token:
 *   Student sends "hello":
 *     1. admin token → touserid=studentId, text="hello"
 *        → appears in student's Moodle inbox (useridfrom=2/admin, useridto=studentId)
 *     2. admin token → touserid=adminId,   text="hello"
 *        → appears in admin's Moodle inbox  (useridfrom=2/admin, useridto=adminId=self-msg)
 *
 *   Problem with #2: Moodle may block self-messaging.
 *   Better approach: store the student→admin direction in the app's local store
 *   and only sync the student-facing copy to Moodle. Admin sees it via
 *   getMessagesBetween(adminId, studentId) which fetches useridto=adminId,useridfrom=studentId
 *   — but since we sent as admin, useridfrom=2 always.
 *
 * FINAL CLEAN STRATEGY:
 *   - Student sends: admin token sends clean text to studentId (student's inbox).
 *     The message has useridfrom=2 (admin), useridto=studentId.
 *   - Admin fetches conversation with student:
 *     getMessages(useridto=adminId, useridfrom=studentId) → 0 results (student never sent)
 *     getMessages(useridto=studentId, useridfrom=adminId) → all messages (both student-sent
 *     and admin-sent appear here since both go through admin token to studentId)
 *   - The app tracks real sender via the local store senderId field.
 *     Moodle is only used for persistence/delivery, not for sender identity.
 *
 * NO PREFIX. Clean text only. Sender identity comes from the local message store.
 */
const moodleService = require('./moodle.service');

const ADMIN_MOODLE_ID = Number(process.env.MOODLE_ADMIN_ID || 2);

/** Strip HTML tags and decode entities — Moodle wraps text in <p> on return */
const stripHtml = (html) => {
    if (!html) return '';
    return html
        .replace(/<br\s*\/?>/gi, '\n')
        .replace(/<[^>]+>/g, '')
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .replace(/&#91;/g, '[')
        .replace(/&#93;/g, ']')
        .replace(/&nbsp;/g, ' ')
        .trim();
};

class MoodleMessageService {

    /**
     * Verify that a user ID exists in Moodle and return user details.
     * 
     * @param {number} moodleUserId  Moodle user ID to verify
     * @returns {object|null}  Normalized user object if exists, null otherwise
     */
    async verifyUserExists(moodleUserId) {
        if (!moodleUserId || Number.isNaN(Number(moodleUserId))) {
            console.warn(`[MoodleMsg] Invalid user ID: ${moodleUserId}`);
            return null;
        }

        try {
            const userId = Number(moodleUserId);
            console.log(`[MoodleMsg] 🔍 Verifying user ID: ${userId}`);
            
            const user = await moodleService.getUserById(userId);
            
            if (!user) {
                console.error(`[MoodleMsg] ❌ User ID ${userId} not found in Moodle`);
                return null;
            }
            
            const normalized = moodleService.normalizeMoodleUser(user);
            console.log(`[MoodleMsg] ✅ User verified - ID: ${normalized.id}, Name: ${normalized.fullname}`);
            return normalized;
        } catch (err) {
            console.error(`[MoodleMsg] ❌ Error verifying user ${moodleUserId}:`, err.message);
            return null;
        }
    }

    /**
     * Send a message using the sender's own Moodle token
     * This ensures the message appears as sent from the logged-in user
     *
     * @param {number} fromMoodleId  sender Moodle ID
     * @param {number} toMoodleId    recipient Moodle ID (admin)
     * @param {string} text          clean message text
     * @param {string} userToken     sender's personal Moodle token (REQUIRED)
     * @returns {object}  Moodle message object with msgid
     * @throws {Error} If message sending fails
     */
    async sendMessage(fromMoodleId, toMoodleId, text, userToken) {
        const sender = Number(fromMoodleId);
        const recipient = Number(toMoodleId);

        if (isNaN(sender) || isNaN(recipient)) {
            throw new Error(`Invalid user IDs - sender: ${fromMoodleId}, recipient: ${toMoodleId}`);
        }

        if (!text || !String(text).trim()) {
            throw new Error('Message text cannot be empty');
        }

        if (!userToken) {
            throw new Error('User token is required to send messages');
        }

        try {
            // Verify both users exist
            const senderUser = await this.verifyUserExists(sender);
            if (!senderUser) {
                throw new Error(`Sender ID ${sender} not found in Moodle`);
            }

            const recipientUser = await this.verifyUserExists(recipient);
            if (!recipientUser) {
                throw new Error(`Recipient ID ${recipient} not found in Moodle`);
            }

            // Clean message text
            const messageText = String(text).trim();

            console.log(`[MoodleMsg] 📤 Sending message via user token:`);
            console.log(`   - From: ${sender} (${senderUser.fullname})`);
            console.log(`   - To: ${recipient} (${recipientUser.fullname})`);
            console.log(`   - Token: ${userToken.substring(0, 8)}...`);
            
            // Send using user's own token (no fallback to admin token)
            const result = await moodleService.makeRequest(
                'core_message_send_instant_messages',
                {
                    'messages[0][touserid]': recipient,
                    'messages[0][text]': messageText,
                    'messages[0][textformat]': 0,
                },
                userToken  // Use the sender's personal token
            );

            const item = Array.isArray(result) ? result[0] : result;
            if (!item || !item.msgid) {
                throw new Error('Moodle did not return message ID');
            }

            console.log(`[MoodleMsg] ✅ Message sent successfully - MsgID: ${item.msgid}`);
            return item;
        } catch (err) {
            console.error(`[MoodleMsg] ❌ Failed to send message from ${sender} to ${recipient}:`, err.message);
            throw err;
        }
    }

    /**
     * Fetch conversation messages using AJAX endpoint (more reliable for conversations)
     * Falls back to REST API if AJAX fails
     */
    async getConversationMessages(conversationId, limit = 50, sesskey = null) {
        try {
            console.log(`[MoodleMsg] 📨 Fetching conversation ${conversationId}...`);

            // Try AJAX endpoint first if we have a session key
            if (sesskey) {
                try {
                    console.log(`[MoodleMsg] Trying AJAX endpoint with session key...`);
                    const result = await moodleService.makeAjaxRequest(
                        'core_message_get_conversation_messages',
                        {
                            conversationid: conversationId,
                            limitnum: limit,
                            limitfrom: 0,
                            newestfirst: 1,  // ✅ FIX: Fetch newest messages first
                        },
                        sesskey
                    );
                    if (result && result.messages) {
                        console.log(`[MoodleMsg] ✅ Got ${result.messages.length} messages from AJAX endpoint`);
                        return result.messages;
                    }
                } catch (ajaxErr) {
                    console.warn(`[MoodleMsg] ⚠️ AJAX request failed, trying REST API:`, ajaxErr.message);
                }
            }

            // Fallback to REST API
            console.log(`[MoodleMsg] Using REST API fallback...`);
            const result = await moodleService.makeRequest('core_message_get_messages', {
                useridto: 2, // admin
                type: 'conversations',
                newestfirst: 1,  // ✅ FIX: Fetch newest messages first
                limitnum: limit,
            });
            
            if (result?.messages) {
                console.log(`[MoodleMsg] ✅ Got ${result.messages.length} messages from REST API`);
                return result.messages;
            }
            return [];
        } catch (err) {
            console.error(`[MoodleMsg] ❌ Error fetching conversation messages:`, err.message);
            throw err;
        }
    }

    /**
     * Fetch ALL messages between two users (both sent and received)
     * 
     * @param {number} myMoodleId - Current user's Moodle ID
     * @param {number} partnerMoodleId - Conversation partner's Moodle ID
     * @param {number} limit - Max messages to fetch
     * @param {string} sesskey - Optional session key for AJAX endpoint
     * @returns {array} All messages (sent + received) for this conversation
     */
    async getMessagesBetween(myMoodleId, partnerMoodleId, limit = 50, sesskey = null) {
        try {
            const myNum = Number(myMoodleId);
            const partnerNum = Number(partnerMoodleId);
            
            console.log(`[MoodleMsg] 📨 Fetching ALL messages between ${myNum} and ${partnerNum}...`);

            const messages = [];

            // AJAX approach: Fetch from specific conversation
            if (sesskey) {
                try {
                    console.log(`[MoodleMsg] 🔄 Trying AJAX endpoint with session key...`);
                    
                    // Fetch conversations to find the one with our partner
                    let conversationId = null;
                    try {
                        const convResult = await moodleService.makeAjaxRequest(
                            'core_message_get_conversations',
                            {
                                userid: myNum,
                                'conversation[0][type]': 'individual',
                                'conversation[0][userid]': partnerNum,
                            },
                            sesskey
                        );
                        
                        if (convResult?.conversations && Array.isArray(convResult.conversations)) {
                            for (const conv of convResult.conversations) {
                                // Find conversation with our partner
                                if (conv.otheruser?.id === partnerNum) {
                                    conversationId = conv.id;
                                    console.log(`[MoodleMsg] ✅ Found conversation ID: ${conversationId}`);
                                    break;
                                }
                            }
                        }
                    } catch (convErr) {
                        console.warn(`[MoodleMsg] Could not fetch conversations via AJAX:`, convErr.message);
                    }
                    
                    // If we found a conversation, fetch its messages
                    if (conversationId) {
                        const msgResult = await moodleService.makeAjaxRequest(
                            'core_message_get_conversation_messages',
                            {
                                conversationid: conversationId,
                                newestfirst: 1,    // ✅ FIX: Fetch newest messages first
                                limitnum: limit,
                                limitfrom: 0,
                            },
                            sesskey
                        );
                        
                        if (msgResult?.messages && Array.isArray(msgResult.messages)) {
                            console.log(`[MoodleMsg] ✅ Got ${msgResult.messages.length} messages from AJAX (both directions)`);
                            msgResult.messages.sort((a, b) => Number(a.timecreated) - Number(b.timecreated));
                            return msgResult.messages;
                        }
                    }
                } catch (ajaxErr) {
                    console.warn(`[MoodleMsg] ⚠️ AJAX failed:`, ajaxErr.message);
                }
            }

            // REST API fallback: Fetch messages in BOTH directions
            console.log(`[MoodleMsg] 🔄 Using REST API (both directions)...`);
            
            // 1. Fetch messages TO me (other person sent them)
            console.log(`[MoodleMsg]   → Fetching messages TO user ${myNum}...`);
            try {
                const aResult = await moodleService.makeRequest('core_message_get_messages', {
                    useridto: myNum,
                    type: 'conversations',
                    newestfirst: 1,
                    limitnum: limit,
                    limitfrom: 0,
                }, null);

                if (aResult?.messages?.length > 0) {
                    console.log(`[MoodleMsg]   ✅ Got ${aResult.messages.length} messages TO ${myNum}`);
                    messages.push(...aResult.messages);
                }
            } catch (err) {
                console.warn(`[MoodleMsg] Error fetching messages TO ${myNum}:`, err.message);
            }

            // 2. Fetch messages TO partner (I sent them)
            console.log(`[MoodleMsg]   → Fetching messages TO user ${partnerNum} (sent by me)...`);
            try {
                const bResult = await moodleService.makeRequest('core_message_get_messages', {
                    useridto: partnerNum,
                    type: 'conversations',
                    newestfirst: 1,
                    limitnum: limit,
                    limitfrom: 0,
                }, null);

                if (bResult?.messages?.length > 0) {
                    console.log(`[MoodleMsg]   ✅ Got ${bResult.messages.length} messages TO ${partnerNum}`);
                    messages.push(...bResult.messages);
                }
            } catch (err) {
                console.warn(`[MoodleMsg] Error fetching messages TO ${partnerNum}:`, err.message);
            }

            // 🔥 FIXED FILTERING: Keep ONLY messages between these two users
            const filtered = messages.filter(m => {
                const from = Number(m.useridfrom);
                const to = Number(m.useridto);

                return (
                    (from === myNum && to === partnerNum) ||
                    (from === partnerNum && to === myNum)
                );
            });

            console.log("Filtered messages count:", filtered.length);
            
            // ✅ Sort by timestamp (oldest → newest)
            filtered.sort((a, b) => Number(a.timecreated) - Number(b.timecreated));
            
            console.log(`[MoodleMsg] ✅ Final count: ${filtered.length} messages for conversation`);
            if (filtered.length > 0) {
                const first = filtered[0];
                const last = filtered[filtered.length - 1];
                console.log(`[MoodleMsg]    First: ${first.useridfrom}→${first.useridto} at ${new Date(Number(first.timecreated) * 1000).toISOString()}`);
                console.log(`[MoodleMsg]    Last:  ${last.useridfrom}→${last.useridto} at ${new Date(Number(last.timecreated) * 1000).toISOString()}`);
            }
            return filtered;
        } catch (err) {
            console.error(`[MoodleMsg] ❌ Error fetching messages:`, err.message);
            throw err;
        }
    }

    /**
     * Get conversations for a user via admin token.
     */
    async getConversations(moodleUserId, userToken = null) {
        try {
            const result = await moodleService.makeRequest(
                'core_message_get_conversations',
                { userid: Number(moodleUserId), type: 1, limitnum: 50, limitfrom: 0 },
                null
            );
            return Array.isArray(result?.conversations) ? result.conversations : [];
        } catch (err) {
            console.warn('[MoodleMsg] getConversations failed:', err.message);
            return [];
        }
    }

    /**
     * Mark all messages in a conversation as read
     * Uses AJAX endpoint for better reliability
     */
    async markMessagesRead(myMoodleId, partnerMoodleId, sesskey = null) {
        try {
            const myNum = Number(myMoodleId);
            const partnerNum = Number(partnerMoodleId);
            
            console.log(`[MoodleMsg] 📌 Marking messages as read (${myNum} ↔ ${partnerNum})...`);

            // Try AJAX endpoint first (recommended by Moodle)
            if (sesskey) {
                try {
                    console.log(`[MoodleMsg] Using AJAX endpoint to mark as read...`);
                    await moodleService.makeAjaxRequest(
                        'core_message_mark_all_conversation_messages_as_read',
                        {
                            userid: myNum,
                            otheruserid: partnerNum,
                        },
                        sesskey
                    );
                    console.log(`[MoodleMsg] ✅ Messages marked as read via AJAX`);
                    return;
                } catch (ajaxErr) {
                    console.warn(`[MoodleMsg] ⚠️ AJAX mark-read failed:`, ajaxErr.message);
                    // Continue silently - marking read is not critical
                }
            }

            // Silently skip REST API fallback - the API methods are unreliable
            console.log(`[MoodleMsg] ⚠️ Skipping mark-as-read (not critical)`);
        } catch (err) {
            console.warn('[MoodleMsg] markMessagesRead error:', err.message);
            // Silent fail - not critical
        }
    }

    /**
     * Normalize a raw Moodle message into app shape.
     * 
     * 🔥 CRITICAL FIX:
     * Since ALL messages are sent via admin token (useridfrom=2 always),
     * we CANNOT use msg.useridfrom for sender identity. Instead, determine
     * sender based on message direction:
     *   - If msg.useridto == myMoodleId → message is FROM admin TO me
     *   - Otherwise → message is FROM me TO partner
     * 
     * @param {object} msg - Raw Moodle message
     * @param {number} myMoodleId - Current user's Moodle ID
     * @returns {object} Normalized message with correct sender info and clean content
     */
    normalizeMoodleMessage(msg, myMoodleId) {
        const myNum = Number(myMoodleId);
        const msgFrom = Number(msg.useridfrom);
        const msgTo = Number(msg.useridto);
        
        // STEP 1: Get the raw message text (may have HTML tags)
        const rawText = msg.text || msg.smallmessage || '';
        
        // STEP 2: Strip HTML tags to get clean text
        const cleanContent = stripHtml(rawText);
        
        // 🔥 STEP 3: Determine ACTUAL sender based on message direction
        // Since all messages go through admin token, Moodle always shows useridfrom=admin
        // Real sender = who the message is NOT going to
        let senderId;
        let senderRole;
        let senderName;
        
        if (Number(msgTo) === Number(myNum)) {
            // Message is TO me → sender is admin
            senderId = ADMIN_MOODLE_ID;
            senderRole = 'admin';
            senderName = (msg.userfromfullname && msg.userfromfullname.trim()) 
                ? msg.userfromfullname.trim() 
                : 'Admin';
        } else {
            // Message is NOT to me → I am the sender
            senderId = myNum;
            senderRole = 'student';
            senderName = (msg.fullname && msg.fullname.trim()) 
                ? msg.fullname.trim() 
                : `User ${myNum}`;
        }
        
        // 🔥 DEBUG LOGGING: Show original Moodle data vs. corrected sender
        console.log(`[MoodleMsg] Normalizing message ID ${msg.id}:`);
        console.log(`            Moodle useridfrom=${msgFrom} (always admin due to token)`);
        console.log(`            Moodle useridto=${msgTo}`);
        console.log(`            myMoodleId=${myNum}`);
        console.log(`            → Corrected senderId=${senderId} (senderRole=${senderRole})`);
        console.log(`            Content: "${cleanContent.substring(0, 50)}..."`);

        // Return normalized message with CORRECTED sender identity
        return {
            id: String(msg.id),
            type: 'private',
            senderId: `moodle-${senderId}`,        // ✅ CORRECTED sender ID
            senderName: senderName,
            senderRole,
            content: cleanContent,                 // ✅ Clean text, NO prefixes
            groupId: null,
            recipientId: `moodle-${msgTo}`,
            timestamp: new Date(Number(msg.timecreated) * 1000).toISOString(),
            readBy: msg.timeread ? [`moodle-${msgTo}`] : [],
            _moodleRaw: true,
        };
    }

    /**
     * Normalize a Moodle conversation into app Conversation shape.
     */
    async normalizeMoodleConversation(conv, myMoodleId) {
        const members = Array.isArray(conv.members) ? conv.members : [];
        const partner = members.find(m => Number(m.id) !== Number(myMoodleId)) || members[0];

        // Sort messages newest-first to guarantee we get the actual latest
        const messages = Array.isArray(conv.messages) ? [...conv.messages] : [];
        messages.sort((a, b) => Number(b.timecreated) - Number(a.timecreated));
        const lastMsg = messages.length > 0 ? messages[0] : null;

        // Determine partner name with proper resolution
        let partnerName = 'Unknown';
        let partnerId = partner ? `moodle-${partner.id}` : '';
        
        if (partner) {
            const partnerId_num = Number(partner.id);
            
            // First try: use fullname from member object
            if (partner.fullname && partner.fullname.trim() && !partner.fullname.includes('moodle')) {
                partnerName = partner.fullname.trim();
            }
            // Second try: use username from member object
            else if (partner.username && partner.username.trim() && !partner.username.includes('moodle')) {
                partnerName = partner.username.trim();
            }
            // Third try: fetch user details from Moodle
            else if (partnerId_num) {
                try {
                    const userInfo = await this.verifyUserExists(partnerId_num);
                    if (userInfo && userInfo.fullname) {
                        partnerName = userInfo.fullname;
                    } else if (userInfo && userInfo.username) {
                        partnerName = userInfo.username;
                    } else {
                        partnerName = `User ${partnerId_num}`;
                    }
                } catch (err) {
                    console.warn(`[MoodleMsg] Could not fetch partner user info:`, err.message);
                    partnerName = `User ${partnerId_num}`;
                }
            }
        }

        let lastMessage = null;
        if (lastMsg) {
            // Strip HTML tags
            const cleanedContent = stripHtml(lastMsg.text || lastMsg.smallmessage || '');
            
            // Get sender info from message
            const senderId = Number(lastMsg.useridfrom);
            const isAdminSender = senderId === ADMIN_MOODLE_ID;
            
            let senderName;
            if (lastMsg.userfromfullname && lastMsg.userfromfullname.trim()) {
                senderName = lastMsg.userfromfullname.trim();
            } else if (lastMsg.fullname && lastMsg.fullname.trim()) {
                senderName = lastMsg.fullname.trim();
            } else if (isAdminSender) {
                senderName = 'Admin';
            } else {
                senderName = `User ${senderId}`;
            }
            
            lastMessage = {
                id: String(lastMsg.id || ''),
                type: 'private',
                senderId: `moodle-${senderId}`,
                senderName: senderName,
                senderRole: isAdminSender ? 'admin' : 'student',
                content: cleanedContent,
                groupId: null,
                recipientId: `moodle-${myMoodleId}`,
                timestamp: new Date(Number(lastMsg.timecreated) * 1000).toISOString(),
                readBy: lastMsg.timeread ? [`moodle-${myMoodleId}`] : [],
            };
        }

        return {
            partnerId: partnerId,
            partnerName: partnerName,
            lastMessage,
            unread: Number(conv.unreadcount || 0),
        };
    }
}

module.exports = new MoodleMessageService();
