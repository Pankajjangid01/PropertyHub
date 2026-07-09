import { LightningElement } from 'lwc';
import loginUser from '@salesforce/apex/PortalAuthController.loginUser';

export default class PortalLogin extends LightningElement {
    username = '';
    password = '';
    errorMsg = '';
    isLoading = false;
    isPasswordVisible = false;

    get passwordFieldType() {
        return this.isPasswordVisible ? 'text' : 'password';
    }

    get passwordIconName() {
        return this.isPasswordVisible ? 'utility:hide' : 'utility:preview';
    }

    get forgotPasswordUrl() {
        return '/PropertyHub/s/login/ForgotPassword';
    }

    get employeeLoginUrl() {
        // Standard Salesforce internal login page
        return '/login?so=' + this.getOrgIdPlaceholder();
    }

    getOrgIdPlaceholder() {
        // Fallback or dynamically fetch if needed, standard /login usually suffices
        return '';
    }

    handleUsernameChange(event) {
        this.username = event.target.value;
        this.errorMsg = '';
    }

    handlePasswordChange(event) {
        this.password = event.target.value;
        this.errorMsg = '';
    }

    togglePasswordVisibility() {
        this.isPasswordVisible = !this.isPasswordVisible;
    }

    handleKeyPress(event) {
        if (event.code === 'Enter' || event.keyCode === 13) {
            this.handleLogin();
        }
    }

    handleLogin() {
        if (!this.username || !this.password) {
            this.errorMsg = 'Please enter both username and password.';
            return;
        }

        this.isLoading = true;
        this.errorMsg = '';

        // Default start URL after successful login
        const startUrl = '/PropertyHub/s/';

        loginUser({ username: this.username, password: this.password, startUrl: startUrl })
            .then((resultUrl) => {
                // Apex returns the secure authenticated redirect URL
                window.location.href = resultUrl;
            })
            .catch((error) => {
                this.errorMsg = error.body ? error.body.message : 'Invalid credentials or login failed.';
                this.isLoading = false;
            });
    }
}
