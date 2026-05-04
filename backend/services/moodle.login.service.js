/**
 * Moodle Login Service
 * Handles user authentication and token management
 */

const axios = require('axios');

class MoodleLoginService {
    constructor() {
        this.baseUrl = process.env.MOODLE_URL;
        this.serviceName = process.env.MOODLE_SERVICE_NAME || 'moodle_lms_service'; // Required: enable in Moodle admin
    }

    /**
     * Authenticate a user and get their personal token
     * 
     * @param {string} username - Moodle username
     * @param {string} password - User's password
     * @returns {object} { token: string, userid: number, firstname: string, lastname: string, email: string }
     * @throws {Error} If authentication fails
     */
    async authenticateUser(username, password) {
        if (!username || !password) {
            throw new Error('Username and password are required');
        }

        if (!this.baseUrl) {
            throw new Error('MOODLE_URL not configured');
        }

        try {
            console.log(`[MoodleLogin] 🔐 Authenticating user: ${username}`);
            
            const url = `${this.baseUrl}/login/token.php`;
            
            const response = await axios.post(url, null, {
                params: {
                    username: username,
                    password: password,
                    service: this.serviceName,
                },
                timeout: 10000,
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                }
            });

            // Handle Moodle error responses
            if (response.data.error) {
                console.error(`[MoodleLogin] ❌ Authentication failed: ${response.data.error}`);
                throw new Error(response.data.error);
            }

            if (!response.data.token) {
                console.error(`[MoodleLogin] ❌ No token in response`);
                throw new Error('No token returned from Moodle');
            }

            const userInfo = {
                token: response.data.token,
                userid: response.data.userid,
                username: response.data.username,
                firstname: response.data.firstname,
                lastname: response.data.lastname,
                email: response.data.email,
                fullname: `${response.data.firstname} ${response.data.lastname}`,
            };

            console.log(`[MoodleLogin] ✅ User authenticated successfully:`);
            console.log(`   - User ID: ${userInfo.userid}`);
            console.log(`   - Username: ${userInfo.username}`);
            console.log(`   - Token: ${response.data.token.substring(0, 8)}...${response.data.token.substring(response.data.token.length - 4)}`);

            return userInfo;
        } catch (error) {
            console.error(`[MoodleLogin] ❌ Authentication error:`, error.message);
            throw error;
        }
    }

    /**
     * Verify that a token is valid by calling a simple API endpoint
     * 
     * @param {string} token - User's Moodle token
     * @returns {boolean} True if token is valid
     */
    async verifyToken(token) {
        if (!token) {
            return false;
        }

        try {
            console.log(`[MoodleLogin] 🔍 Verifying token...`);
            
            const url = `${this.baseUrl}/webservice/rest/server.php`;
            
            const response = await axios.get(url, {
                params: {
                    wstoken: token,
                    wsfunction: 'core_webservice_get_site_info',
                    moodlewsrestformat: 'json',
                },
                timeout: 5000,
            });

            if (response.data && response.data.sitename) {
                console.log(`[MoodleLogin] ✅ Token is valid`);
                return true;
            }

            console.warn(`[MoodleLogin] ⚠️ Token verification failed`);
            return false;
        } catch (error) {
            console.warn(`[MoodleLogin] ⚠️ Token invalid:`, error.message);
            return false;
        }
    }

    /**
     * Get user details from Moodle using their token
     * 
     * @param {string} token - User's Moodle token
     * @returns {object} User information
     */
    async getUserInfo(token) {
        if (!token) {
            throw new Error('Token is required');
        }

        try {
            console.log(`[MoodleLogin] 👤 Fetching user info...`);
            
            const url = `${this.baseUrl}/webservice/rest/server.php`;
            
            const response = await axios.get(url, {
                params: {
                    wstoken: token,
                    wsfunction: 'core_webservice_get_site_info',
                    moodlewsrestformat: 'json',
                },
                timeout: 5000,
            });

            if (response.data && response.data.userid) {
                return {
                    userid: response.data.userid,
                    username: response.data.username,
                    firstname: response.data.firstname,
                    lastname: response.data.lastname,
                    fullname: response.data.fullname,
                    email: response.data.email,
                };
            }

            throw new Error('Invalid response from Moodle');
        } catch (error) {
            console.error(`[MoodleLogin] ❌ Error fetching user info:`, error.message);
            throw error;
        }
    }
}

module.exports = new MoodleLoginService();
