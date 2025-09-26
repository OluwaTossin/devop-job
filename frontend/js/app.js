/**
 * DevOps Job Portal - Frontend Application
 * 
 * Main JavaScript application for the DevOps job portal featuring:
 * - Job application submission with file uploads
 * - Admin authentication and session management
 * - Application management interface
 * - Responsive UI interactions
 * 
 * @author DevOps Job Portal Team
 * @date September 2025
 */

// API Configuration - Placeholder replaced in CI per environment (dev/prod)
// Do not change this placeholder manually; the GitHub Actions workflow replaces it with the actual API URL.
// Environment-aware API configuration
const hostname = window.location.hostname;
let API_BASE_URL;

if (hostname.includes('prod')) {
    // Production environment
    API_BASE_URL = 'https://rta8dvqii9.execute-api.eu-west-1.amazonaws.com/prod';
} else {
    // Development environment (default)
    API_BASE_URL = 'https://8rq5va2dy8.execute-api.eu-west-1.amazonaws.com/dev';
}

// Global application state
let applications = [];
let isAdminAuthenticated = false;
let authToken = null;

// DOM element references for performance optimization
const elements = {
    applicationForm: document.getElementById('applicationForm'),
    loadingSpinner: document.getElementById('loadingSpinner'),
    successMessage: document.getElementById('successMessage'),
    errorMessage: document.getElementById('errorMessage'),
    errorText: document.getElementById('errorText'),
    fileInput: document.getElementById('cv'),
    fileInfo: document.getElementById('fileInfo'),
    applicationsLoading: document.getElementById('applicationsLoading'),
    applicationsList: document.getElementById('applicationsList'),
    noApplications: document.getElementById('noApplications'),
    applicationsCount: document.getElementById('applicationsCount'),
    refreshApplications: document.getElementById('refreshApplications'),
    // Authentication modal elements (dynamically created)
    adminLoginModal: null,
    loginForm: null,
    loginError: null,
    logoutBtn: null
};

/**
 * Initialize the application when DOM is loaded
 */
document.addEventListener('DOMContentLoaded', function() {
    initializeEventListeners();
    checkAuthStatus();
    loadApplications();
    checkAPIConfiguration();
});
function initializeEventListeners() {
    // Application form submission
    if (elements.applicationForm) {
        elements.applicationForm.addEventListener('submit', handleApplicationSubmit);
    }
    
    // File input change
    if (elements.fileInput) {
        elements.fileInput.addEventListener('change', handleFileSelect);
    }
    
    // Refresh applications button
    if (elements.refreshApplications) {
        elements.refreshApplications.addEventListener('click', loadApplications);
    }
    
    // Tab buttons
    const tabButtons = document.querySelectorAll('.tab-button');
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            const tabName = button.getAttribute('onclick')?.match(/showTab\\('(.+?)'\\)/)?.[1];
            if (tabName) {
                showTab(tabName);
            }
        });
    });
}

// Handle file selection
function handleFileSelect(event) {
    const file = event.target.files[0];
    const fileInfo = elements.fileInfo;
    
    if (file) {
        // Check file size (5MB limit)
        const maxSize = 5 * 1024 * 1024; // 5MB in bytes
        if (file.size > maxSize) {
            alert('File size must be less than 5MB');
            event.target.value = '';
            fileInfo.style.display = 'none';
            return;
        }
        
        // Check file type
        const allowedTypes = ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];
        if (!allowedTypes.includes(file.type)) {
            alert('Please upload a PDF, DOC, or DOCX file');
            event.target.value = '';
            fileInfo.style.display = 'none';
            return;
        }
        
        // Show file info
        fileInfo.innerHTML = `
            <i class="fas fa-file"></i>
            Selected: ${file.name} (${formatFileSize(file.size)})
        `;
        fileInfo.style.display = 'block';
    } else {
        fileInfo.style.display = 'none';
    }
}

// Format file size
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// ============================================
// AUTHENTICATION FUNCTIONS
// ============================================

// Check authentication status on page load
function checkAuthStatus() {
    const token = localStorage.getItem('adminToken');
    const expiry = localStorage.getItem('adminTokenExpiry');
    
    if (token && expiry && new Date().getTime() < parseInt(expiry)) {
        isAdminAuthenticated = true;
        authToken = token;
        showAdminContent();
    } else {
        clearAuth();
    }
}

// Show admin login modal
function showAdminLogin() {
    if (!elements.adminLoginModal) {
        createLoginModal();
    }
    elements.adminLoginModal.style.display = 'flex';
}

// Create login modal HTML
function createLoginModal() {
    const modalHTML = `
        <div id="adminLoginModal" class="auth-modal">
            <div class="auth-modal-content">
                <div class="auth-header">
                    <h3>Admin Login</h3>
                    <button class="auth-close" onclick="closeLoginModal()">&times;</button>
                </div>
                <form id="adminLoginForm" class="auth-form">
                    <div class="form-group">
                        <label for="adminUsername">Username:</label>
                        <input type="text" id="adminUsername" name="username" required>
                    </div>
                    <div class="form-group">
                        <label for="adminPassword">Password:</label>
                        <input type="password" id="adminPassword" name="password" required>
                    </div>
                    <div id="loginError" class="error-message" style="display: none;"></div>
                    <button type="submit" class="btn btn-primary">Login</button>
                </form>
            </div>
        </div>
    `;
    
    document.body.insertAdjacentHTML('beforeend', modalHTML);
    
    // Update element references
    elements.adminLoginModal = document.getElementById('adminLoginModal');
    elements.loginForm = document.getElementById('adminLoginForm');
    elements.loginError = document.getElementById('loginError');
    
    // Add event listeners
    elements.loginForm.addEventListener('submit', handleAdminLogin);
}

// Close login modal
function closeLoginModal() {
    if (elements.adminLoginModal) {
        elements.adminLoginModal.style.display = 'none';
        elements.loginForm.reset();
        elements.loginError.style.display = 'none';
    }
}

// Handle admin login
async function handleAdminLogin(event) {
    event.preventDefault();
    
    const formData = new FormData(elements.loginForm);
    const credentials = {
        username: formData.get('username'),
        password: formData.get('password')
    };
    
    try {
        const response = await fetch(`${API_BASE_URL}/admin/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(credentials)
        });
        
        const data = await response.json();
        
        if (response.ok && data.success) {
            // Store auth token with expiry (24 hours)
            const expiryTime = new Date().getTime() + (24 * 60 * 60 * 1000);
            localStorage.setItem('adminToken', data.token);
            localStorage.setItem('adminTokenExpiry', expiryTime.toString());
            
            isAdminAuthenticated = true;
            authToken = data.token;
            
            closeLoginModal();
            showAdminContent();
            loadApplications(); // Refresh applications
        } else {
            showLoginError(data.message || 'Invalid credentials');
        }
    } catch (error) {
        console.error('Login error:', error);
        showLoginError('Connection error. Please try again.');
    }
}

// Show login error
function showLoginError(message) {
    elements.loginError.textContent = message;
    elements.loginError.style.display = 'block';
}

// Show admin content
function showAdminContent() {
    // Show admin tab and hide login prompt
    const adminTab = document.getElementById('admin');
    if (adminTab) {
        const loginPrompt = adminTab.querySelector('.login-prompt');
        const adminContent = adminTab.querySelector('.admin-content');
        
        if (loginPrompt) loginPrompt.style.display = 'none';
        if (adminContent) adminContent.style.display = 'block';
    }
    
    // Add logout button if not exists
    addLogoutButton();
}

// Add logout button
function addLogoutButton() {
    if (!elements.logoutBtn) {
        const adminHeader = document.querySelector('#admin .admin-header');
        if (adminHeader) {
            const logoutBtn = document.createElement('button');
            logoutBtn.textContent = 'Logout';
            logoutBtn.className = 'btn btn-secondary logout-btn';
            logoutBtn.onclick = handleLogout;
            adminHeader.appendChild(logoutBtn);
            elements.logoutBtn = logoutBtn;
        }
    }
}

// Handle logout
function handleLogout() {
    clearAuth();
    
    // Hide admin content and show login prompt
    const adminTab = document.getElementById('admin');
    if (adminTab) {
        const loginPrompt = adminTab.querySelector('.login-prompt');
        const adminContent = adminTab.querySelector('.admin-content');
        
        if (loginPrompt) loginPrompt.style.display = 'block';
        if (adminContent) adminContent.style.display = 'none';
    }
    
    // Switch to application tab
    showTab('application');
}

// Clear authentication
function clearAuth() {
    isAdminAuthenticated = false;
    authToken = null;
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminTokenExpiry');
    
    if (elements.logoutBtn) {
        elements.logoutBtn.remove();
        elements.logoutBtn = null;
    }
}

// Modified showTab function to check admin authentication
function showTab(tabName) {
    // Check if trying to access admin tab
    if (tabName === 'admin' && !isAdminAuthenticated) {
        showAdminLogin();
        return;
    }
    
    // Hide all tab contents
    const tabContents = document.querySelectorAll('.tab-content');
    const tabButtons = document.querySelectorAll('.tab-button');
    
    tabContents.forEach(content => {
        content.classList.remove('active');
    });
    
    tabButtons.forEach(button => {
        button.classList.remove('active');
    });
    
    // Show selected tab
    document.getElementById(tabName).classList.add('active');
    event.target.classList.add('active');
    
    // Load applications if admin tab is selected and authenticated
    if (tabName === 'admin' && isAdminAuthenticated) {
        loadApplications();
    }
}

// ============================================
// END AUTHENTICATION FUNCTIONS
// ============================================

// Handle application form submission
async function handleApplicationSubmit(event) {
    event.preventDefault();
    
    // Show loading spinner
    elements.loadingSpinner.style.display = 'block';
    elements.successMessage.style.display = 'none';
    elements.errorMessage.style.display = 'none';
    
    try {
        // Get form data
        const formData = new FormData(elements.applicationForm);
        
        // Convert to JSON (except file)
        const applicationData = {
            firstName: formData.get('firstName'),
            lastName: formData.get('lastName'),
            email: formData.get('email'),
            phone: formData.get('phone'),
            experience: formData.get('experience'),
            location: formData.get('location'),
            skills: formData.get('skills'),
            coverLetter: formData.get('coverLetter'),
            terms: formData.get('terms') === 'on'
        };
        
        // Handle file upload
        const file = formData.get('cv');
        if (file && file.size > 0) {
            applicationData.cv = await fileToBase64(file);
            applicationData.cvFileName = file.name;
            applicationData.cvFileType = file.type;
        }
        
        // Submit application
        const response = await fetch(`${API_BASE_URL}/applications`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(applicationData)
        });
        
        if (response.ok) {
            const result = await response.json();
            showSuccessMessage();
            elements.applicationForm.reset();
            elements.fileInfo.style.display = 'none';
        } else {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Submission failed');
        }
    } catch (error) {
        console.error('Application submission error:', error);
        showErrorMessage(error.message);
    } finally {
        elements.loadingSpinner.style.display = 'none';
    }
}

// Convert file to base64
function fileToBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.readAsDataURL(file);
        reader.onload = () => resolve(reader.result.split(',')[1]); // Remove data:mime;base64, prefix
        reader.onerror = error => reject(error);
    });
}

// Show success message
function showSuccessMessage() {
    elements.successMessage.style.display = 'block';
    elements.successMessage.scrollIntoView({ behavior: 'smooth' });
    
    // Hide after 10 seconds
    setTimeout(() => {
        elements.successMessage.style.display = 'none';
    }, 10000);
}

// Show error message
function showErrorMessage(message) {
    elements.errorText.textContent = message || 'An error occurred. Please try again.';
    elements.errorMessage.style.display = 'block';
    elements.errorMessage.scrollIntoView({ behavior: 'smooth' });
    
    // Hide after 10 seconds
    setTimeout(() => {
        elements.errorMessage.style.display = 'none';
    }, 10000);
}

// Load applications for admin panel
async function loadApplications() {
    if (!elements.applicationsList) return;
    
    elements.applicationsLoading.style.display = 'block';
    elements.noApplications.style.display = 'none';
    elements.applicationsList.innerHTML = '';
    
    try {
        const response = await fetch(`${API_BASE_URL}/applications`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            }
        });
        
        if (response.ok) {
            const data = await response.json();
            applications = data.applications || [];
            displayApplications(applications);
        } else {
            throw new Error('Failed to load applications');
        }
    } catch (error) {
        console.error('Error loading applications:', error);
        elements.applicationsList.innerHTML = `
            <div class="error-message" style="padding: 20px; text-align: center; color: #dc3545;">
                <i class="fas fa-exclamation-triangle"></i>
                <p>Failed to load applications. Please check your API configuration.</p>
                <p><small>${error.message}</small></p>
            </div>
        `;
    } finally {
        elements.applicationsLoading.style.display = 'none';
    }
}

// Display applications in admin panel
function displayApplications(applications) {
    const container = elements.applicationsList;
    const countBadge = elements.applicationsCount;
    
    // Update count
    countBadge.textContent = applications.length;
    
    if (applications.length === 0) {
        elements.noApplications.style.display = 'block';
        return;
    }
    
    container.innerHTML = applications.map(app => {
        const skills = app.skills ? app.skills.split(',').map(skill => 
            `<span class="skill-tag">${skill.trim()}</span>`
        ).join('') : '';
        
        const submittedDate = new Date(app.submitted_at || app.createdAt).toLocaleDateString();
        
        return `
            <div class="application-card">
                <div class="application-header">
                    <div class="applicant-name">
                        ${app.first_name} ${app.last_name}
                    </div>
                    <div class="application-date">
                        <i class="fas fa-calendar"></i> ${submittedDate}
                    </div>
                </div>
                
                <div class="application-details">
                    <div class="detail-item">
                        <i class="fas fa-envelope"></i>
                        <span>${app.email}</span>
                    </div>
                    ${app.phone ? `
                    <div class="detail-item">
                        <i class="fas fa-phone"></i>
                        <span>${app.phone}</span>
                    </div>
                    ` : ''}
                    <div class="detail-item">
                        <i class="fas fa-briefcase"></i>
                        <span>${app.experience} experience</span>
                    </div>
                    ${app.location ? `
                    <div class="detail-item">
                        <i class="fas fa-map-marker-alt"></i>
                        <span>${app.location}</span>
                    </div>
                    ` : ''}
                </div>
                
                ${skills ? `
                <div class="skills-list">
                    <strong>Skills:</strong>
                    ${skills}
                </div>
                ` : ''}
                
                ${app.cover_letter ? `
                <div style="margin-top: 15px;">
                    <strong>Cover Letter:</strong>
                    <p style="margin-top: 8px; padding: 15px; background: #f8f9fa; border-radius: 8px; white-space: pre-line;">
                        ${app.cover_letter.length > 200 ? 
                            app.cover_letter.substring(0, 200) + '...' : 
                            app.cover_letter}
                    </p>
                </div>
                ` : ''}
                
                <div class="application-actions">
                    <button class="btn-view" onclick="viewFullApplication('${app.id || app.application_id}')">
                        <i class="fas fa-eye"></i> View Full Application
                    </button>
                    ${app.cv_file_path ? `
                    <button class="btn-view" onclick="downloadCV('${app.id || app.application_id}')">
                        <i class="fas fa-download"></i> Download CV
                    </button>
                    ` : ''}
                    <button class="btn-delete" onclick="deleteApplication('${app.id || app.application_id}', '${app.first_name} ${app.last_name}')">
                        <i class="fas fa-trash"></i> Delete Application
                    </button>
                </div>
            </div>
        `;
    }).join('');
}

// View full application details
async function viewFullApplication(applicationId) {
    console.log('viewFullApplication called with ID:', applicationId);
    console.log('API_BASE_URL:', API_BASE_URL);
    
    try {
        const url = `${API_BASE_URL}/applications/${applicationId}`;
        console.log('Fetching URL:', url);
        
        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            }
        });
        
        console.log('Response status:', response.status);
        console.log('Response ok:', response.ok);
        
        if (response.ok) {
            const application = await response.json();
            console.log('Application data:', application);
            showApplicationModal(application);
        } else {
            const errorText = await response.text();
            console.error('API Error Response:', errorText);
            throw new Error(`Failed to load application details: ${response.status}`);
        }
    } catch (error) {
        console.error('Error loading application details:', error);
        alert(`Failed to load application details: ${error.message}`);
    }
}

// Download CV
async function downloadCV(applicationId) {
    console.log('downloadCV called with ID:', applicationId);
    console.log('API_BASE_URL:', API_BASE_URL);
    
    try {
        // Get application details to retrieve CV download URL
        const url = `${API_BASE_URL}/applications/${applicationId}`;
        console.log('Fetching URL for CV download:', url);
        
        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        });

        console.log('CV Download Response status:', response.status);
        
        if (!response.ok) {
            const errorText = await response.text();
            console.error('API Error Response:', errorText);
            throw new Error(`Failed to fetch application details: ${response.status}`);
        }

        const application = await response.json();
        console.log('Application data for CV download:', application);
        
        if (!application.cv_download_url) {
            console.error('No cv_download_url in response');
            alert('CV file not available for this application');
            return;
        }

        console.log('CV Download URL:', application.cv_download_url);

        // Create a temporary link element and trigger download
        const link = document.createElement('a');
        link.href = application.cv_download_url;
        link.download = application.cv_file_name || `cv_${applicationId}.pdf`;
        link.target = '_blank';
        
        console.log('Triggering download for:', link.download);
        
        // Append to body, click, and remove
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
    } catch (error) {
        console.error('Error downloading CV:', error);
        alert(`Failed to download CV: ${error.message}`);
    }
}

// Delete application
async function deleteApplication(applicationId, applicantName) {
    console.log('deleteApplication called with ID:', applicationId, 'Name:', applicantName);
    console.log('API_BASE_URL:', API_BASE_URL);
    
    // Show confirmation dialog
    const confirmDelete = confirm(
        `Are you sure you want to delete the application from ${applicantName}?\n\n` +
        `This action will:\n` +
        `• Remove the application from the database\n` +
        `• Delete the uploaded CV file\n` +
        `• This action cannot be undone\n\n` +
        `Click OK to confirm deletion, or Cancel to abort.`
    );
    
    if (!confirmDelete) {
        console.log('Delete cancelled by user');
        return;
    }
    
    try {
        const url = `${API_BASE_URL}/applications/${applicationId}`;
        console.log('Deleting at URL:', url);
        
        const response = await fetch(url, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
            }
        });
        
        console.log('Delete Response status:', response.status);
        console.log('Delete Response ok:', response.ok);
        
        if (response.ok) {
            const result = await response.json();
            console.log('Delete result:', result);
            
            // Show success message
            alert(`Application from ${applicantName} has been successfully deleted.`);
            
            // Refresh the applications list
            await loadApplications();
            
        } else {
            const errorText = await response.text();
            console.error('Delete API Error Response:', errorText);
            
            let errorMessage = 'Failed to delete application';
            try {
                const errorData = JSON.parse(errorText);
                if (errorData.message) {
                    errorMessage = errorData.message;
                }
            } catch (parseError) {
                // Use default message if can't parse JSON
            }
            
            throw new Error(`${errorMessage}: ${response.status}`);
        }
    } catch (error) {
        console.error('Error deleting application:', error);
        alert(`Failed to delete application: ${error.message}`);
    }
}

// Show application modal (simplified version)
function showApplicationModal(application) {
    const modalContent = `
        <div style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.8); z-index: 1000; display: flex; align-items: center; justify-content: center; padding: 20px;" onclick="closeModal(event)">
            <div style="background: white; border-radius: 15px; padding: 30px; max-width: 600px; max-height: 90vh; overflow-y: auto; position: relative;" onclick="event.stopPropagation()">
                <button style="position: absolute; top: 15px; right: 20px; background: none; border: none; font-size: 1.5rem; cursor: pointer;" onclick="closeModal()">&times;</button>
                
                <h2>${application.first_name} ${application.last_name}</h2>
                <hr style="margin: 20px 0;">
                
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px;">
                    <div><strong>Email:</strong><br>${application.email}</div>
                    ${application.phone ? `<div><strong>Phone:</strong><br>${application.phone}</div>` : ''}
                    <div><strong>Experience:</strong><br>${application.experience}</div>
                    ${application.location ? `<div><strong>Location:</strong><br>${application.location}</div>` : ''}
                </div>
                
                ${application.skills ? `
                <div style="margin-bottom: 20px;">
                    <strong>Skills:</strong><br>
                    <div style="margin-top: 8px;">
                        ${application.skills.split(',').map(skill => 
                            `<span style="display: inline-block; background: #667eea; color: white; padding: 4px 12px; border-radius: 15px; font-size: 0.85rem; margin: 2px;">${skill.trim()}</span>`
                        ).join('')}
                    </div>
                </div>
                ` : ''}
                
                ${application.cover_letter ? `
                <div style="margin-bottom: 20px;">
                    <strong>Cover Letter:</strong><br>
                    <div style="margin-top: 8px; padding: 15px; background: #f8f9fa; border-radius: 8px; white-space: pre-line;">
                        ${application.cover_letter}
                    </div>
                </div>
                ` : ''}
                
                <div style="text-align: center; margin-top: 20px;">
                    <button onclick="closeModal()" style="background: #6c757d; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer;">Close</button>
                </div>
            </div>
        </div>
    `;
    
    const modal = document.createElement('div');
    modal.innerHTML = modalContent;
    modal.id = 'applicationModal';
    document.body.appendChild(modal);
}

// Close modal
function closeModal(event) {
    if (!event || event.target === event.currentTarget) {
        const modal = document.getElementById('applicationModal');
        if (modal) {
            modal.remove();
        }
    }
}

// Check API configuration
function checkAPIConfiguration() {
    if (API_BASE_URL.includes('your-api-gateway-url')) {
        console.warn('API URL not configured. Please update API_BASE_URL in app.js after deploying infrastructure.');
        
        // Show configuration notice
        const notice = document.createElement('div');
        notice.innerHTML = `
            <div style="background: #fff3cd; border: 1px solid #ffeaa7; color: #856404; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <strong><i class="fas fa-exclamation-triangle"></i> Configuration Required:</strong>
                <p>Please update the API_BASE_URL in frontend/js/app.js with your API Gateway URL after deploying the infrastructure.</p>
            </div>
        `;
        
        const container = document.querySelector('.container');
        container.insertBefore(notice, container.firstChild);
    }
}

// Utility functions
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Form validation helpers
function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

function validatePhone(phone) {
    const re = /^[+]?[\d\s\-\(\)]{10,}$/;
    return re.test(phone);
}

// Export functions for global access
window.showTab = showTab;
window.viewFullApplication = viewFullApplication;
window.downloadCV = downloadCV;
window.closeModal = closeModal;