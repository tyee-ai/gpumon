// GPU RRD Monitor Dashboard JavaScript

let isAnalysisRunning = false;

document.addEventListener('DOMContentLoaded', function() {
    // Set default dates
    const today = new Date();
    const lastWeek = new Date(today.getTime() - (7 * 24 * 60 * 60 * 1000));
    
    document.getElementById('start_date').value = lastWeek.toISOString().split('T')[0];
    document.getElementById('end_date').value = today.toISOString().split('T')[0];
    
    // Form submission handler
    const form = document.getElementById('analysisForm');
    form.addEventListener('submit', function(e) {
        e.preventDefault();
        runAnalysis();
    });
});

function runAnalysis() {
    if (isAnalysisRunning) {
        return; // Prevent multiple submissions
    }
    
    isAnalysisRunning = true;
    
    // Show loading spinner
    document.getElementById('loadingSpinner').style.display = 'block';
    document.getElementById('resultsSection').style.display = 'none';
    
    // Disable form
    const submitBtn = document.querySelector('button[type="submit"]');
    const originalText = submitBtn.innerHTML;
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Running...';
    
    // Get form data
    const formData = new FormData(document.getElementById('analysisForm'));
    const params = new URLSearchParams();
    
    for (let [key, value] of formData.entries()) {
        params.append(key, value);
    }
    
    // Make API call
    fetch(`/api/analysis?${params.toString()}`)
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                displayResults(data);
            } else {
                showError(data.error || 'Analysis failed');
            }
        })
        .catch(error => {
            console.error('Error:', error);
            showError('Network error occurred');
        })
        .finally(() => {
            // Hide loading spinner
            document.getElementById('loadingSpinner').style.display = 'none';
            
            // Re-enable form
            submitBtn.disabled = false;
            submitBtn.innerHTML = originalText;
            
            isAnalysisRunning = false;
        });
}

function displayResults(data) {
    const resultsSection = document.getElementById('resultsSection');
    const summaryCards = document.getElementById('summaryCards');
    const throttledSection = document.getElementById('throttledSection');
    const thermallyFailedSection = document.getElementById('thermallyFailedSection');
    const rawOutput = document.getElementById('rawOutput');
    
    // Display summary cards
    displaySummaryCards(data.results.summary);
    
    // Display throttled alerts
    displayThrottledAlerts(data.results.throttled);
    
    // Display thermally failed alerts
    displayThermallyFailedAlerts(data.results.thermally_failed);
    
    // Display raw output
    rawOutput.textContent = data.raw_output;
    
    // Show results section
    resultsSection.style.display = 'block';
    
    // Scroll to results
    resultsSection.scrollIntoView({ behavior: 'smooth' });
}

function displaySummaryCards(summary) {
    const summaryCards = document.getElementById('summaryCards');
    
    let html = '';
    
    // Total devices
    if (summary.total_devices) {
        html += `
            <div class="summary-card summary-total">
                <h4><i class="fas fa-server text-success"></i></h4>
                <h3>${summary.total_devices}</h3>
                <p class="text-muted">Total Devices</p>
            </div>
        `;
    }
    
    // Throttled count
    if (summary.throttled_count) {
        html += `
            <div class="summary-card summary-throttled">
                <h4><i class="fas fa-fire text-danger"></i></h4>
                <h3>${summary.throttled_count}</h3>
                <p class="text-muted">Throttled GPUs</p>
            </div>
        `;
    }
    
    // Suspicious count
    if (summary.suspicious_count) {
        html += `
            <div class="summary-card summary-thermally-failed">
                <h4><i class="fas fa-exclamation-triangle text-warning"></i></h4>
                <h3>${summary.suspicious_count}</h3>
                <p class="text-muted">Thermally Failed</p>
            </div>
        `;
    }
    
    summaryCards.innerHTML = html;
}

function displayThrottledAlerts(alerts) {
    const container = document.getElementById('throttledAlerts');
    
    if (!alerts || alerts.length === 0) {
        container.innerHTML = '<div class="alert alert-success">✅ No throttled GPUs found</div>';
        return;
    }
    
    let html = '';
    alerts.forEach(alert => {
        html += `
            <div class="alert alert-danger alert-card alert-throttled">
                <div class="row">
                    <div class="col-md-3">
                        <strong><i class="fas fa-fire"></i> ${alert.gpu_id}</strong>
                    </div>
                    <div class="col-md-3">
                        <strong>Device:</strong> ${alert.device}
                    </div>
                    <div class="col-md-3">
                        <strong>Temperature:</strong> ${alert.temp}°C
                    </div>
                    <div class="col-md-3">
                        <strong>Time:</strong> ${formatTimestamp(alert.timestamp)}
                    </div>
                </div>
            </div>
        `;
    });
    
    container.innerHTML = html;
}

function displayThermallyFailedAlerts(alerts) {
    const container = document.getElementById('thermallyFailedAlerts');
    
    if (!alerts || alerts.length === 0) {
        container.innerHTML = '<div class="alert alert-success">✅ No thermally failed GPUs found</div>';
        container.style.display = 'none';
        return;
    }
    
    container.style.display = 'block';
    
    let html = '';
    alerts.forEach(alert => {
        html += `
            <div class="alert alert-warning alert-card alert-thermally-failed">
                <div class="row">
                    <div class="col-md-2">
                        <strong><i class="fas fa-exclamation-triangle"></i> ${alert.gpu_id}</strong>
                    </div>
                    <div class="col-md-2">
                        <strong>Device:</strong> ${alert.device}
                    </div>
                    <div class="col-md-2">
                        <strong>Temperature:</strong> ${alert.temp}°C
                    </div>
                    <div class="col-md-2">
                        <strong>Average:</strong> ${alert.avg_temp}°C
                    </div>
                    <div class="col-md-2">
                        <strong>Time:</strong> ${formatTimestamp(alert.timestamp)}
                    </div>
                </div>
            </div>
        `;
    });
    
    container.innerHTML = html;
}

function formatTimestamp(timestamp) {
    try {
        const date = new Date(timestamp);
        return date.toLocaleDateString("en-US", { month: "2-digit", day: "2-digit", year: "numeric" });
    } catch (e) {
        return timestamp;
    }
}

function showError(message) {
    // Create error alert
    const errorAlert = document.createElement('div');
    errorAlert.className = 'alert alert-danger alert-dismissible fade show';
    errorAlert.innerHTML = `
        <i class="fas fa-exclamation-circle"></i> ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    // Insert at top of main container
    const mainContainer = document.querySelector('.main-container');
    mainContainer.insertBefore(errorAlert, mainContainer.firstChild);
    
    // Auto-remove after 10 seconds
    setTimeout(() => {
        if (errorAlert.parentNode) {
            errorAlert.remove();
        }
    }, 10000);
}
