/**
 * Password Validation Utility
 * Enforces Moodle-compatible password requirements
 */

const PASSWORD_RULES = {
    minLength: 8,
    minLowerCase: 1,
    minUpperCase: 1,
    minSpecialChars: 1,
    specialCharacters: ['*', '-', '#', '!', '@', '$', '%', '^', '&', '+', '=', '_', '~'],
};

/**
 * Validate password against Moodle requirements
 * @param {string} password - Password to validate
 * @returns {object} - { isValid: boolean, errors: string[] }
 */
const validatePassword = (password) => {
    const errors = [];

    if (!password || typeof password !== 'string') {
        return {
            isValid: false,
            errors: ['Password is required'],
        };
    }

    const trimmedPassword = password.trim();

    // Check minimum length
    if (trimmedPassword.length < PASSWORD_RULES.minLength) {
        errors.push(`Passwords must be at least ${PASSWORD_RULES.minLength} characters long.`);
    }

    // Check for at least 1 lowercase letter
    if (!trimmedPassword.match(/[a-z]/)) {
        errors.push('Passwords must have at least 1 lower case letter(s).');
    }

    // Check for at least 1 uppercase letter
    if (!trimmedPassword.match(/[A-Z]/)) {
        errors.push('Passwords must have at least 1 upper case letter(s).');
    }

    // Check for at least 1 special character
    const hasSpecialChar = PASSWORD_RULES.specialCharacters.some((char) =>
        trimmedPassword.includes(char)
    );
    if (!hasSpecialChar) {
        errors.push(
            `The password must have at least 1 special character(s) such as ${PASSWORD_RULES.specialCharacters.join(', ')}.`
        );
    }

    return {
        isValid: errors.length === 0,
        errors,
    };
};

/**
 * Get formatted password requirements message
 * @returns {string} - Formatted requirements message
 */
const getPasswordRequirementsText = () => {
    return `Password Requirements:\n` +
        `• Passwords must be at least ${PASSWORD_RULES.minLength} characters long.\n` +
        `• Passwords must have at least 1 lower case letter(s).\n` +
        `• Passwords must have at least 1 upper case letter(s).\n` +
        `• The password must have at least 1 special character(s) such as ${PASSWORD_RULES.specialCharacters.slice(0, 3).join(', ')}.`;
};

module.exports = {
    validatePassword,
    getPasswordRequirementsText,
    PASSWORD_RULES,
};
