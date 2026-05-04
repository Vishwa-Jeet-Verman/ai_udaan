const axios = require('axios');

/**
 * Moodle Web Service Integration
 * Provides methods to interact with Moodle LMS
 */
class MoodleService {
    constructor() {
        this.baseUrl = process.env.MOODLE_URL;
        this.token = process.env.MOODLE_TOKEN;
        this.createUserToken = process.env.MOODLE_CREATE_USER_TOKEN;
        this.courseToken = process.env.MOODLE_COURSE_TOKEN;
        
        if (!this.baseUrl) {
            console.error('[Moodle] ERROR: MOODLE_URL not set in .env');
        }
        if (!this.token) {
            console.error('[Moodle] ERROR: MOODLE_TOKEN not set in .env');
        }
    }

    /**
     * Test Moodle connection
     */
    async testConnection() {
        try {
            console.log('[Moodle] Testing connection...');
            console.log('[Moodle] Base URL:', this.baseUrl);
            console.log('[Moodle] Token:', this.token ? `***${this.token.slice(-4)}` : 'NOT SET');
            
            const result = await this.makeRequest('core_webservice_get_site_info');
            console.log('[Moodle] ✅ Connection successful!');
            console.log('[Moodle] Site name:', result.sitename);
            return true;
        } catch (error) {
            console.error('[Moodle] ❌ Connection failed:', error.message);
            return false;
        }
    }

    /**
     * Make a request to Moodle Web Service
     */
    async makeRequest(wsfunction, params = {}, customToken = null) {
        try {
            const url = `${this.baseUrl}/webservice/rest/server.php`;
            const token = customToken || this.token;

            console.log(`[Moodle API] 🔄 Calling: ${wsfunction}`);
            console.log(`[Moodle API] URL: ${url}`);
            console.log(`[Moodle API] Token: ${token ? `***${token.slice(-4)}` : 'NOT SET'}`);
            console.log(`[Moodle API] Params:`, JSON.stringify(params));

            const response = await axios.get(url, {
                params: {
                    wstoken: token,
                    wsfunction: wsfunction,
                    moodlewsrestformat: 'json',
                    ...params,
                },
                timeout: 30000,
            });

            console.log(`[Moodle API] ✅ Response Status:`, response.status);
            console.log(`[Moodle API] Response Data Type:`, typeof response.data);
            console.log(`[Moodle API] Response Data Keys:`, Object.keys(response.data || {}));

            // Check for Moodle errors
            if (response.data && response.data.exception) {
                const errorParts = [
                    response.data.message,
                    response.data.debuginfo,
                    response.data.errorcode ? `errorcode=${response.data.errorcode}` : null,
                ].filter(Boolean);
                const errorMsg = errorParts.join(' | ') || 'Moodle API error';
                console.error(`[Moodle API] ❌ Moodle Error:`, errorMsg);
                throw new Error(errorMsg);
            }

            // Log response for debugging
            if (Array.isArray(response.data)) {
                console.log(`[Moodle API] ✅ Returned array with ${response.data.length} items`);
            } else if (typeof response.data === 'object') {
                console.log(`[Moodle API] ✅ Returned object`, response.data);
            }

            return response.data;
        } catch (error) {
            console.error(`[Moodle API] ❌ Error calling ${wsfunction}:`, error.message);
            if (error.response?.data) {
                console.error('[Moodle API] Response Data:', JSON.stringify(error.response.data, null, 2));
            }
            throw error;
        }
    }

    /**
     * Make a request to Moodle AJAX service endpoint (lib/ajax/service.php)
     * Used for conversation-based messaging endpoints
     */
    async makeAjaxRequest(wsfunction, params = {}, sesskey) {
        try {
            const url = `${this.baseUrl}/lib/ajax/service.php`;

            console.log(`[Moodle AJAX] 🔄 Calling: ${wsfunction}`);
            console.log(`[Moodle AJAX] URL: ${url}`);
            console.log(`[Moodle AJAX] SessionKey: ${sesskey ? `***${sesskey.slice(-4)}` : 'NOT SET'}`);
            console.log(`[Moodle AJAX] Params:`, JSON.stringify(params));

            const response = await axios.post(url, params, {
                params: {
                    sesskey: sesskey,
                    info: wsfunction,
                },
                headers: {
                    'Content-Type': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest',
                },
                timeout: 30000,
            });

            console.log(`[Moodle AJAX] ✅ Response Status:`, response.status);
            console.log(`[Moodle AJAX] Response Data:`, JSON.stringify(response.data).substring(0, 200));

            // Check for Moodle errors
            if (response.data && response.data.error) {
                console.error(`[Moodle AJAX] ❌ Moodle Error:`, response.data.error);
                throw new Error(response.data.error);
            }

            return response.data;
        } catch (error) {
            console.error(`[Moodle AJAX] ❌ Error calling ${wsfunction}:`, error.message);
            if (error.response?.data) {
                console.error('[Moodle AJAX] Response Data:', JSON.stringify(error.response.data, null, 2));
            }
            throw error;
        }
    }

    /**
     * Create a new Moodle user via Web Service.
     */
    async createUser({ username, password, firstname, lastname, email }) {
        const tokenToUse = this.createUserToken || this.token;
        if (!tokenToUse) {
            throw new Error('MOODLE_CREATE_USER_TOKEN is not configured.');
        }

        const result = await this.makeRequest(
            'core_user_create_users',
            {
                'users[0][username]': username,
                'users[0][password]': password,
                'users[0][firstname]': firstname,
                'users[0][lastname]': lastname,
                'users[0][email]': email,
                'users[0][auth]': 'manual',
            },
            tokenToUse
        );

        if (Array.isArray(result) && result.length > 0) {
            return result[0];
        }

        if (result && Array.isArray(result.users) && result.users.length > 0) {
            return result.users[0];
        }

        throw new Error('Moodle user creation did not return a created user record.');
    }

    /**
     * Get all courses from Moodle.
     *
     * Uses `core_course_search_courses` first because it includes image fields
     * (`courseimage` / `overviewfiles`) that the dashboard needs.
     */
    async getAllCourses() {
        try {
            console.log('[Moodle] 📚 Fetching all courses from Moodle...');

            let courses = [];

            // Use core_course_get_courses to get all courses with the `visible` field reliably.
            // core_course_search_courses with empty string does not filter by visibility.
            const result = await this.makeRequest('core_course_get_courses');
            if (Array.isArray(result)) {
                courses = result;
            } else if (result && Array.isArray(result.courses)) {
                courses = result.courses;
            }
            console.log('[Moodle] 📊 core_course_get_courses returned', courses.length, 'courses');
            courses.forEach(c => console.log(`[Moodle]   Course id=${c.id} visible=${c.visible} name="${c.fullname}"`));

            // Fetch overview images via search API and merge them in
            try {
                const searchResult = await this.makeRequest('core_course_search_courses', {
                    criterianame: 'search',
                    criteriavalue: '',
                });
                if (searchResult && Array.isArray(searchResult.courses)) {
                    const imageMap = new Map(
                        searchResult.courses.map(c => [String(c.id), c])
                    );
                    courses = courses.map(c => {
                        const withImage = imageMap.get(String(c.id));
                        if (withImage) {
                            return {
                                ...c,
                                overviewfiles: withImage.overviewfiles || c.overviewfiles,
                                courseimage: withImage.courseimage || c.courseimage,
                            };
                        }
                        return c;
                    });
                }
            } catch (_) {
                // image enrichment is best-effort
            }

            const filteredCourses = courses.filter((course) => {
                if (!course || Number(course.id) === 1) return false;
                // Only show courses explicitly marked visible=1
                return Number(course.visible) === 1;
            });
            console.log(`[Moodle] ✅ Found ${filteredCourses.length} visible courses (filtered from ${courses.length})`);

            return filteredCourses;
        } catch (error) {
            console.error('[Moodle] ❌ Error fetching courses:', error.message);
            return [];
        }
    }

    /**
     * Get user's enrolled courses from Moodle
     */
    async getUserCourses(userId) {
        try {
            console.log(`[Moodle] 🔄 Fetching enrollments for user ${userId}...`);
            const result = await this.makeRequest('core_enrol_get_users_courses', {
                userid: userId,
            });

            let courses = [];
            if (Array.isArray(result)) {
                courses = result;
            } else if (result && result.courses) {
                courses = result.courses;
            }
            
            courses = courses.filter(c => {
                if (!c || c.id === 1) return false;
                if (c.visible !== undefined && c.visible !== null) {
                    return Number(c.visible) !== 0;
                }
                return true;
            });
            console.log(`[Moodle] ✅ Found ${courses.length} enrolled courses`);
            return courses;
        } catch (error) {
            console.error(`[Moodle] ❌ Error fetching courses:`, error.message);
            return [];
        }
    }

    /**
     * Authenticate with Moodle using username and password
     */
    async authenticateWithPassword(username, password) {
        try {
            console.log(`[Moodle] 🔐 Authenticating user: ${username}`);
            const url = `${this.baseUrl}/login/token.php`;
            const serviceName = process.env.MOODLE_SERVICE_NAME || 'moodle_mobile_app';
            
            const response = await axios.get(url, {
                params: {
                    username: username,
                    password: password,
                    service: serviceName,
                },
                timeout: 30000,
            });

            if (response.data && response.data.token) {
                console.log(`[Moodle] ✅ Authentication successful for user: ${username}`);
                
                // Get user details
                const userDetails = await this.makeRequest(
                    'core_webservice_get_site_info',
                    {},
                    response.data.token
                );
                
                return {
                    id: userDetails.userid,
                    username: userDetails.username,
                    firstname: userDetails.firstname,
                    lastname: userDetails.lastname,
                    fullname: userDetails.fullname,
                    email: userDetails.useremail,
                    profileimageurl: userDetails.userpictureurl,
                    moodleToken: response.data.token,
                };
            }
            
            console.error(`[Moodle] ❌ Authentication failed: No token returned`);
            return null;
        } catch (error) {
            console.error(`[Moodle] ❌ Authentication failed:`, error.message);
            if (error.response?.data) {
                console.error('[Moodle] Error response:', error.response.data);
            }
            return null;
        }
    }

    /**
     * Get user by arbitrary field from Moodle.
     */
    async getUserByField(field, value) {
        if (!field || !value) {
            return null;
        }

        const normalizeFieldValue = (input) => String(input || '').trim().toLowerCase();
        const hasExactFieldMatch = (user) => {
            if (!user || user[field] === undefined || user[field] === null) {
                return false;
            }
            return normalizeFieldValue(user[field]) === normalizeFieldValue(value);
        };

        try {
            const result = await this.makeRequest('core_user_get_users_by_field', {
                field,
                'values[0]': value,
            });

            if (Array.isArray(result) && result.length > 0) {
                const exactMatch = result.find(hasExactFieldMatch);
                return exactMatch || null;
            }

            return null;
        } catch (error) {
            // Fallback for Moodle instances where get_users_by_field is unavailable.
            try {
                const fallback = await this.makeRequest('core_user_get_users', {
                    'criteria[0][key]': field,
                    'criteria[0][value]': value,
                });

                if (fallback && Array.isArray(fallback.users) && fallback.users.length > 0) {
                    const exactMatch = fallback.users.find(hasExactFieldMatch);
                    return exactMatch || null;
                }

                return null;
            } catch (fallbackError) {
                console.error(`Error fetching user by ${field}:`, fallbackError.message);
                return null;
            }
        }
    }

    /**
     * Get user by username from Moodle
     */
    async getUserByUsername(username) {
        return this.getUserByField('username', username);
    }

    /**
     * Get user by email from Moodle
     */
    async getUserByEmail(email) {
        return this.getUserByField('email', email);
    }

    /**
     * Get user by Moodle numeric ID.
     */
    async getUserById(userId) {
        if (userId === undefined || userId === null) return null;
        return this.getUserByField('id', String(userId));
    }

    /**
     * Normalize Moodle user payload into a stable shape.
     */
    normalizeMoodleUser(user) {
        if (!user) return null;

        const firstname = user.firstname || '';
        const lastname = user.lastname || '';
        const fullNameFromParts = [firstname, lastname].filter(Boolean).join(' ').trim();

        return {
            id: Number(user.id || user.userid || 0) || null,
            username: user.username || null,
            firstname,
            lastname,
            fullname: user.fullname || fullNameFromParts || user.username || '',
            email: user.email || user.useremail || null,
            profileimageurl:
                user.profileimageurl ||
                user.profileimageurlsmall ||
                user.userpictureurl ||
                null,
        };
    }

    /**
     * Resolve the best matching Moodle user for a local app user.
     */
    async resolveMoodleUserForLocalUser(localUser) {
        if (!localUser) return null;

        const normalizeValue = (value) => String(value || '').trim().toLowerCase();

        // If moodle_id is already known, prefer it first.
        if (localUser.moodle_id) {
            const byId = this.normalizeMoodleUser(await this.getUserById(localUser.moodle_id));
            if (byId) {
                return byId;
            }
        }

        const usernameCandidates = new Set();
        if (localUser.username) {
            usernameCandidates.add(String(localUser.username).trim());
        }
        if (localUser.email && String(localUser.email).includes('@')) {
            const localPart = String(localUser.email).split('@')[0].trim();
            if (localPart) {
                usernameCandidates.add(localPart);
            }
        }

        for (const usernameCandidate of usernameCandidates) {
            const byUsername = this.normalizeMoodleUser(
                await this.getUserByUsername(usernameCandidate)
            );
            if (
                byUsername &&
                normalizeValue(byUsername.username) === normalizeValue(usernameCandidate)
            ) {
                return byUsername;
            }
        }

        if (localUser.email) {
            const byEmail = this.normalizeMoodleUser(await this.getUserByEmail(localUser.email));
            if (
                byEmail &&
                normalizeValue(byEmail.email) === normalizeValue(localUser.email)
            ) {
                return byEmail;
            }
        }

        return null;
    }

    /**
     * Check enrollment from Moodle only.
     */
    async isUserEnrolledInCourse(moodleUserId, courseId) {
        if (!moodleUserId || !courseId) return false;
        const moodleCourses = await this.getUserCourses(moodleUserId);
        return moodleCourses.some((course) => Number(course?.id) === Number(courseId));
    }

    /**
     * Enroll a Moodle user in a course using manual enrollment.
     */
    async enrollUserInCourse(moodleUserId, courseId, userToken = null) {
        if (!moodleUserId || !courseId) {
            throw new Error('Missing Moodle user or course id for enrollment.');
        }

        const courseIdNum = Number(courseId);
        const studentRoleId = Number(process.env.MOODLE_STUDENT_ROLE_ID || 5);

        // STRATEGY 1: Admin manual enrolment (preferred — works regardless of per-course setup)
        try {
            const enrolToken = process.env.MOODLE_ENROL_TOKEN || this.courseToken || this.token;
            await this.makeRequest('enrol_manual_enrol_users', {
                'enrolments[0][roleid]': studentRoleId,
                'enrolments[0][userid]': Number(moodleUserId),
                'enrolments[0][courseid]': courseIdNum,
            }, enrolToken);

            // Wait briefly for Moodle to sync before verification
            await new Promise(r => setTimeout(r, 500));
            return this.isUserEnrolledInCourse(moodleUserId, courseId);
        } catch (manualErr) {
            const msg = String(manualErr?.message || '').toLowerCase();
            if (msg.includes('already enrolled')) {
                return this.isUserEnrolledInCourse(moodleUserId, courseId);
            }
            // accessexception means function not in service — fall through to self-enrol
            if (!msg.includes('accessexception') && !msg.includes('access control')) {
                throw manualErr;
            }
            console.warn('[Moodle] enrol_manual_enrol_users not available, trying self-enrol...');
        }

        // STRATEGY 2: Self-enrolment fallback (requires per-course self-enrol method enabled)
        try {
            const methods = await this.makeRequest('core_enrol_get_course_enrolment_methods', {
                courseid: courseIdNum,
            });

            console.log('[Moodle] 🔍 Available enrollment methods:', JSON.stringify(methods, null, 2));

            // Accept any self-enrollment method that exists (let Moodle enforce permissions)
            const selfMethod = Array.isArray(methods)
                ? methods.find(m => m.type === 'self')
                : null;

            console.log('[Moodle] 📋 Looking for self-enrollment method...');
            console.log('[Moodle] Found self-method:', selfMethod ? JSON.stringify(selfMethod) : 'none');

            if (!selfMethod) {
                console.log('[Moodle] ❌ No self-enrollment method found. Available methods:', methods.map(m => ({ type: m.type, status: m.status })));
                throw new Error('Enrolment is not enabled for this course. Please contact the admin.');
            }

            const tokenToUse = userToken || this.token;
            await this.makeRequest('enrol_self_enrol_user', {
                courseid: courseIdNum,
                instanceid: selfMethod.id,
            }, tokenToUse);

            // Wait a bit longer for self-enrollment to sync (Moodle may need more time)
            await new Promise(r => setTimeout(r, 1000));

        } catch (selfErr) {
            const msg = String(selfErr?.message || '').toLowerCase();
            if (!msg.includes('already enrolled')) {
                throw selfErr;
            }
        }

        return this.isUserEnrolledInCourse(moodleUserId, courseId);
    }

    /**
     * Update a user's profile fields (e.g. firstname, lastname) in Moodle.
     */
    async updateUserProfile(moodleUserId, { firstname, lastname } = {}) {
        if (!moodleUserId) {
            throw new Error('Missing user ID for profile update.');
        }

        const tokenToUse = this.createUserToken || this.token;
        const params = { 'users[0][id]': Number(moodleUserId) };
        if (firstname !== undefined) params['users[0][firstname]'] = firstname;
        if (lastname !== undefined) params['users[0][lastname]'] = lastname;

        try {
            await this.makeRequest('core_user_update_users', params, tokenToUse);
            console.log(`[Moodle] ✅ Profile updated for user ${moodleUserId}`);
            return true;
        } catch (error) {
            console.error(`[Moodle] ❌ Failed to update profile for user ${moodleUserId}:`, error.message);
            throw error;
        }
    }

    /**
     * Update a user's password in Moodle.
     */
    async updateUserPassword(moodleUserId, newPassword) {
        if (!moodleUserId || !newPassword) {
            throw new Error('Missing user ID or password for update.');
        }

        const tokenToUse = this.createUserToken || this.token;

        try {
            const result = await this.makeRequest(
                'core_user_update_users',
                {
                    'users[0][id]': Number(moodleUserId),
                    'users[0][password]': newPassword,
                },
                tokenToUse
            );

            console.log(`[Moodle] ✅ Password updated for user ${moodleUserId}`);
            return true;
        } catch (error) {
            console.error(`[Moodle] ❌ Failed to update password for user ${moodleUserId}:`, error.message);
            throw error;
        }
    }

    /**
     * Get course by ID from Moodle.
     */
    async getCourseById(courseId) {
        try {
            const result = await this.makeRequest('core_course_get_courses_by_field', {
                field: 'id',
                value: String(courseId),
            });

            if (result && Array.isArray(result.courses) && result.courses.length > 0) {
                return result.courses[0];
            }

            // Fallback for Moodle instances that don't support this response shape.
            const allCourses = await this.getAllCourses();
            return allCourses.find((course) => Number(course?.id) === Number(courseId)) || null;
        } catch (error) {
            console.error('[Moodle] ❌ Error fetching course by ID:', error.message);
            const allCourses = await this.getAllCourses();
            return allCourses.find((course) => Number(course?.id) === Number(courseId)) || null;
        }
    }

    /**
     * Get all sections/modules for a Moodle course.
     */
    async getCourseContents(courseId) {
        try {
            const result = await this.makeRequest('core_course_get_contents', {
                courseid: courseId,
            });

            if (Array.isArray(result)) {
                console.log(`[Moodle] 📚 Course ${courseId}: ${result.length} sections found`);
                result.forEach((section, idx) => {
                    console.log(`[Moodle]   Section ${idx + 1}: "${section.name}" (${section.modules?.length || 0} modules)`);
                    if (section.modules && section.modules.length > 0) {
                        section.modules.forEach((mod, modIdx) => {
                            console.log(`[Moodle]     Module ${modIdx + 1}: id=${mod.id}, name="${mod.name}", modname="${mod.modname}"`);
                        });
                    }
                });
                return result;
            }

            return [];
        } catch (error) {
            console.error('[Moodle] ❌ Error fetching course contents:', error.message);
            return [];
        }
    }

    /**
     * Ensure a Moodle URL can be opened directly by attaching token when needed.
     */
    appendTokenToUrl(rawUrl, customToken = null) {
        if (!rawUrl) return null;

        try {
            const url = new URL(rawUrl);
            const base = new URL(this.baseUrl);

            // Only inject token for same Moodle host.
            if (url.host === base.host) {
                // /webservice/pluginfile.php returns 422 — rewrite to /pluginfile.php
                if (url.pathname.startsWith('/webservice/pluginfile.php')) {
                    url.pathname = url.pathname.replace('/webservice/pluginfile.php', '/pluginfile.php');
                }
                if (!url.searchParams.has('token')) {
                    url.searchParams.set('token', customToken || this.token);
                }
            }

            return url.toString();
        } catch (_) {
            return rawUrl;
        }
    }

    /**
     * Convert Moodle course payload to the backend API contract used by Flutter.
     */
    mapCourseToApi(course) {
        const decodeHtmlEntities = (value) =>
            String(value || '')
                .replace(/&nbsp;/gi, ' ')
                .replace(/&amp;/gi, '&')
                .replace(/&lt;/gi, '<')
                .replace(/&gt;/gi, '>')
                .replace(/&quot;/gi, '"')
                .replace(/&#39;/gi, "'")
                .replace(/&#x27;/gi, "'")
                .replace(/&#(\d+);/g, (_, dec) => String.fromCharCode(Number(dec)))
                .replace(/&#x([0-9a-f]+);/gi, (_, hex) =>
                    String.fromCharCode(parseInt(hex, 16))
                );

        const stripTagsAndDecode = (value) => {
            const withoutTags = String(value || '').replace(/<[^>]*>/g, ' ');
            return decodeHtmlEntities(withoutTags).replace(/\s+/g, ' ').trim();
        };

        const parseNumericValue = (value) => {
            if (value === null || value === undefined) return null;
            if (typeof value === 'number' && Number.isFinite(value)) return value;

            const normalized = stripTagsAndDecode(value).replace(/,/g, '');
            if (!normalized) return null;

            const match = normalized.match(/-?\d+(?:\.\d+)?/);
            if (!match) return null;

            const parsed = Number(match[0]);
            return Number.isFinite(parsed) ? parsed : null;
        };

        const sanitizeSummary = (summary) => {
            const raw = String(summary || '');
            if (!raw.trim()) return null;
            const withoutTags = raw.replace(/<[^>]*>/g, ' ');
            const decoded = decodeHtmlEntities(withoutTags);
            const compact = decoded.replace(/\s+/g, ' ').trim();
            return compact || null;
        };

        const customFields = Array.isArray(course?.customfields)
            ? course.customfields
            : [];

        const findCustomField = (...keys) => {
            const normalizedKeys = keys
                .map((key) => String(key || '').trim().toLowerCase())
                .filter(Boolean);

            if (normalizedKeys.length === 0) return null;

            return (
                customFields.find((field) => {
                    const name = String(field?.name || '').trim().toLowerCase();
                    const shortName = String(field?.shortname || '').trim().toLowerCase();
                    return (
                        normalizedKeys.includes(name) || normalizedKeys.includes(shortName)
                    );
                }) || null
            );
        };

        const resolveCoursePrice = () => {
            const directCandidates = [
                course?.price,
                course?.cost,
                course?.fee,
                course?.amount,
                course?.enrollmentcost,
            ];

            for (const candidate of directCandidates) {
                const parsed = parseNumericValue(candidate);
                if (parsed !== null && parsed >= 0) return parsed;
            }

            const customField = findCustomField(
                'cost',
                'price',
                'fee',
                'amount',
                'course_cost',
                'course_price'
            );

            if (!customField) return 0;

            const parsedCustomPrice =
                parseNumericValue(customField.valueraw) ??
                parseNumericValue(customField.value);

            if (parsedCustomPrice === null || parsedCustomPrice < 0) {
                return 0;
            }

            return parsedCustomPrice;
        };

        const title = course?.displayname || course?.fullname || '';

        const firstOverviewFile =
            Array.isArray(course?.overviewfiles) && course.overviewfiles.length > 0
                ? course.overviewfiles[0]
                : null;

        // Prefer overviewfiles (real uploaded image) over courseimage (may be a generated SVG)
        // Filter out Moodle's auto-generated SVG placeholders — they return text/html, not images
        const rawCourseImage = course?.courseimage || null;
        const isGeneratedSvg = rawCourseImage && rawCourseImage.includes('/course/generated/');
        const rawThumbnail = firstOverviewFile?.fileurl
            || (!isGeneratedSvg ? rawCourseImage : null)
            || null;
        const thumbnail = this.appendTokenToUrl(rawThumbnail);

        // Local fallback images keyed by title keywords (used when Moodle image is unavailable)
        const baseUrl = process.env.BASE_URL || 'http://localhost:9000';
        const localFallbacks = [
            { keywords: ['gen', 'generative'], file: 'gen_ai.png' },
            { keywords: ['deep', 'learning'], file: 'deep_learning.png' },
            { keywords: ['computer', 'vision'], file: 'computer_vision.png' },
            { keywords: ['nlp', 'natural', 'language'], file: 'nlp.png' },
            { keywords: ['ml', 'machine', 'fundamental'], file: 'ml_fundamentals.png' },
            { keywords: ['ai', 'artificial', 'intro'], file: 'ai_intro.png' },
        ];
        const titleLower = title.toLowerCase();
        const fallbackMatch = localFallbacks.find(f =>
            f.keywords.some(k => titleLower.includes(k))
        );
        const fallbackThumbnail = fallbackMatch
            ? `${baseUrl}/uploads/${fallbackMatch.file}`
            : null;

        // Use Moodle thumbnail if available, otherwise local fallback
        const resolvedThumbnail = thumbnail || fallbackThumbnail;

        // Proxy Moodle images through our backend so Flutter clients
        // don't need direct access to Moodle (avoids CORS/network issues on emulator)
        const finalThumbnail = resolvedThumbnail && resolvedThumbnail.startsWith('https://moodle.')
            ? `${baseUrl}/api/proxy/image?url=${encodeURIComponent(resolvedThumbnail)}`
            : resolvedThumbnail;

        const createdAt = course?.timecreated
            ? new Date(Number(course.timecreated) * 1000).toISOString()
            : null;

        const resolvedPrice = resolveCoursePrice();

        return {
            id: String(course?.id ?? ''),
            title,
            description: sanitizeSummary(course?.summary),
            price: resolvedPrice,
            thumbnail_url: finalThumbnail,
            created_by: 'moodle',
            status: 'approved',
            created_at: createdAt,
            updated_at: createdAt,
            creator: {
                id: 'moodle',
                name: 'Moodle',
            },
        };
    }

    /**
     * Send a Moodle instant message from admin to a user.
     * This creates a real entry in Moodle's messaging/notification system.
     * userfromid: admin Moodle ID (MOODLE_ADMIN_ID)
     * usertoid:   recipient Moodle ID
     */
    async sendMoodleMessage(usertoid, subject, text) {
        if (!usertoid) return false;
        const adminId = Number(process.env.MOODLE_ADMIN_ID || 2);
        try {
            await this.makeRequest('core_message_send_instant_messages', {
                'messages[0][touserid]':  Number(usertoid),
                'messages[0][text]':      text || subject,
                'messages[0][textformat]': 0,
                'messages[0][clientmsgid]': `lms-${Date.now()}`,
            });
            return true;
        } catch (err) {
            console.error('[Moodle] sendMoodleMessage error:', err.message);
            return false;
        }
    }

    /**
     * Get popup notifications for a user from Moodle.
     * Uses the user's own token so Moodle returns their personal notifications.
     * Falls back to empty array if the function is not available.
     */
    async getMoodleNotifications(moodleUserId, userToken, { limit = 50, offset = 0 } = {}) {
        if (!moodleUserId || !userToken) return [];

        const results = [];

        // 1. Try popup notifications (system events like grade, assignment, etc.)
        try {
            const result = await this.makeRequest(
                'message_popup_get_popup_notifications',
                { useridto: Number(moodleUserId), newestfirst: 1, limit, offset },
                userToken
            );
            const notifications = result?.notifications || result || [];
            if (Array.isArray(notifications)) results.push(...notifications);
        } catch (_) {}

        // 2. Also fetch inbox messages (catches enrollment messages sent via sendMoodleMessage)
        try {
            const inbox = await this.makeRequest(
                'core_message_get_messages',
                {
                    useridto: Number(moodleUserId),
                    useridfrom: Number(process.env.MOODLE_ADMIN_ID || 2),
                    type: 'notifications',
                    read: 0,
                    newestfirst: 1,
                    limitnum: limit,
                    limitfrom: offset,
                },
                userToken
            );
            const messages = inbox?.messages || [];
            if (Array.isArray(messages)) results.push(...messages);
        } catch (_) {}

        // 3. Also try read notifications so panel shows history
        try {
            const readResult = await this.makeRequest(
                'core_message_get_messages',
                {
                    useridto: Number(moodleUserId),
                    useridfrom: Number(process.env.MOODLE_ADMIN_ID || 2),
                    type: 'notifications',
                    read: 1,
                    newestfirst: 1,
                    limitnum: limit,
                    limitfrom: offset,
                },
                userToken
            );
            const readMessages = readResult?.messages || [];
            if (Array.isArray(readMessages)) results.push(...readMessages);
        } catch (_) {}

        // Deduplicate by id, newest first
        const seen = new Set();
        return results
            .filter((n) => {
                if (!n || seen.has(n.id)) return false;
                seen.add(n.id);
                return true;
            })
            .sort((a, b) => (b.timecreated || 0) - (a.timecreated || 0));
    }

    /**
     * Mark a Moodle notification as read.
     */
    async markMoodleNotificationRead(notificationId, userToken) {
        if (!notificationId || !userToken) return false;
        try {
            await this.makeRequest(
                'core_message_mark_notification_read',
                {
                    notificationid: Number(notificationId),
                    timeread: Math.floor(Date.now() / 1000),
                },
                userToken
            );
            return true;
        } catch (_) {
            return false;
        }
    }

    /**
     * Mark all Moodle notifications as read for a user.
     */
    async markAllMoodleNotificationsRead(moodleUserId, userToken) {
        if (!moodleUserId || !userToken) return false;
        try {
            await this.makeRequest(
                'core_message_mark_all_notifications_as_read',
                { useridto: Number(moodleUserId) },
                userToken
            );
            return true;
        } catch (_) {
            return false;
        }
    }
    async getEnrolledUsers(courseId) {
        try {
            const result = await this.makeRequest('core_enrol_get_enrolled_users', {
                courseid: Number(courseId),
            });
            return Array.isArray(result) ? result : [];
        } catch (error) {
            console.error(`[Moodle] ❌ Error fetching enrolled users for course ${courseId}:`, error.message);
            return [];
        }
    }

    /**
     * Upload a profile picture to Moodle for a given user.
     * Steps: upload file to draft area → update user with userpicture draft item id.
     * @param {number} moodleUserId  - Moodle user ID
     * @param {string} userToken     - The user's own Moodle token (needed for upload)
     * @param {string} filePath      - Absolute path to the image file on disk
     * @param {string} filename      - Filename to use in Moodle
     */
    async uploadUserProfilePicture(moodleUserId, userToken, filePath, filename) {
        const FormData = require('form-data');
        const fs = require('fs');

        if (!moodleUserId || !filePath) {
            throw new Error('Missing required params for Moodle profile picture upload.');
        }

        try {
            // Use MOODLE_TOKEN for file upload (has upload permissions)
            // Use MOODLE_CREATE_USER_TOKEN for profile update (has user management permissions)
            const uploadToken = this.token;
            const updateToken = this.createUserToken || this.token;

            console.log(`[Moodle] 📸 Uploading profile picture for user ${moodleUserId}...`);

            const uploadUrl = `${this.baseUrl}/webservice/upload.php`;
            const form = new FormData();
            form.append('token', uploadToken);
            form.append('filearea', 'draft');
            form.append('itemid', '0');
            form.append('filepath', '/');
            form.append('filename', 'avatar.jpg');
            form.append('file_1', fs.createReadStream(filePath), {
                filename: 'avatar.jpg',
                contentType: 'image/jpeg',
            });

            const uploadResponse = await axios.post(uploadUrl, form, {
                headers: form.getHeaders(),
                timeout: 30000,
            });

            console.log('[Moodle] Upload response:', JSON.stringify(uploadResponse.data));

            const uploadedFiles = Array.isArray(uploadResponse.data)
                ? uploadResponse.data
                : [uploadResponse.data];

            if (!uploadedFiles[0] || uploadedFiles[0].error) {
                throw new Error(uploadedFiles[0]?.error || 'Moodle file upload failed');
            }

            const draftItemId = uploadedFiles[0].itemid;
            console.log(`[Moodle] ✅ File uploaded to draft area, itemid: ${draftItemId}`);

            // Update profile picture using create-user token (has core_user_update_users permission)
            await this.makeRequest('core_user_update_users', {
                'users[0][id]': Number(moodleUserId),
                'users[0][userpicture]': draftItemId,
            }, updateToken);

            console.log(`[Moodle] ✅ Profile picture updated for user ${moodleUserId}`);
            return true;

        } catch (error) {
            console.error(`[Moodle] ❌ Failed to upload profile picture:`, error.message);
            if (error.response?.data) {
                console.error('[Moodle] Response data:', JSON.stringify(error.response.data));
            }
            return false;
        }
    }

    /**
     * Sync user's Moodle enrollments to local database
     */
    async syncUserEnrollments(userId) {
        try {
            const moodleCourses = await this.getUserCourses(userId);
            
            if (!moodleCourses || moodleCourses.length === 0) {
                console.log(`[Moodle] User ${userId} has no courses in Moodle`);
                return [];
            }

            console.log(`[Moodle] User ${userId} has ${moodleCourses.length} courses in Moodle`);
            return moodleCourses;
        } catch (error) {
            console.error('[Moodle] Error syncing user enrollments:', error);
            return [];
        }
    }
}

module.exports = new MoodleService();
