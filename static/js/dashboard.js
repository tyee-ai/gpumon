// GPU RRD Monitor Dashboard JavaScript

let isAnalysisRunning = false;

// Helper function to generate DNS name from IP address
function generateDNSName(ipAddress) {
    if (!ipAddress) return "Unknown";
    return `${ipAddress}.voltagepark.net`;
}

document.addEventListener('DOMContentLoaded', function() {
    console.log('DOM loaded - dashboard.js loaded successfully');
    
    // Set default dates
    const today = new Date();
    const lastWeek = new Date(today.getTime() - (7 * 24 * 60 * 60 * 1000));
    
    document.getElementById('start_date').value = lastWeek.toISOString().split('T')[0];
    document.getElementById('end_date').value = today.toISOString().split('T')[0];
    
    // Form submission handler
    const form = document.getElementById('analysisForm');
    form.addEventListener('submit', function(e) {
        e.preventDefault();
        console.log('Form submitted - running analysis');
        runAnalysis();
    });
    
    console.log('Dashboard initialization complete');
});

// Test function to manually test the display
function testDisplay() {
    console.log('Test display function called');
    
    const testData = {
        results: {
            summary: {
                throttled_count: 9,
                total_devices: 253,
                planned_gpu_nodes: 254,
                planned_total_gpus: 2032,
                total_records: 28052,
                total_alerts: 1390
            },
            throttled: [
                {
                    site: "DFW2",
                    cluster: "C1",
                    device: "10.4.11.38",
                    gpu_id: "GPU_23",
                    max_temp: 93.0,
                    first_date: "2025-07-25 00:00:00",
                    last_date: "2025-07-25 16:00:00",
                    days_throttled: 1,
                    alert_count: 3
                }
            ]
        }
    };
    
    console.log('Test data:', testData);
    displayResults(testData);
}

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
    try {
        console.log('displayResults called with:', data);
        
        const resultsSection = document.getElementById('resultsSection');
        const summaryCards = document.getElementById('summaryCards');
        const throttledSection = document.getElementById('throttledSection');
        const thermallyFailedSection = document.getElementById('thermallyFailedSection');
        
        console.log('DOM elements found:', {
            resultsSection: !!resultsSection,
            summaryCards: !!summaryCards,
            throttledSection: !!throttledSection,
            thermallyFailedSection: !!thermallyFailedSection
        });
        
        // Display summary cards
        displaySummaryCards(data.results.summary);
        
        // Display throttled alerts
        console.log('Throttled alerts to display:', data.results.throttled);
        displayThrottledAlerts(data.results.throttled);
        
        // Display thermally failed alerts
        displayThermallyFailedAlerts(data.results.thermally_failed);
        
        // Show results section
        if (resultsSection) {
            resultsSection.style.display = 'block';
            // Scroll to results
            resultsSection.scrollIntoView({ behavior: 'smooth' });
        }
    } catch (error) {
        console.error('Error in displayResults:', error);
    }
}

function displaySummaryCards(summary) {
    const summaryCards = document.getElementById('summaryCards');
    
    let html = '';
    
    // GPU Infrastructure Summary
    html += `
        <div class="summary-card summary-gpu-nodes">
            <h4><i class="fas fa-microchip text-success"></i></h4>
            <h3>${summary.planned_gpu_nodes || 254}</h3>
            <p class="text-muted">GPU Nodes</p>
        </div>
    `;
    
    // Total GPUs
    html += `
        <div class="summary-card summary-total-gpus">
            <h4><i class="fas fa-server text-info"></i></h4>
            <h3>${summary.planned_total_gpus || 2032}</h3>
            <p class="text-muted">Total GPUs</p>
        </div>
    `;
    
    // GPU Devices Found (filtered count)
    if (summary.total_devices && summary.total_devices !== 'N/A') {
        html += `
            <div class="summary-card summary-gpu-found">
                <h4><i class="fas fa-search text-warning"></i></h4>
                <h3>${summary.total_devices}</h3>
                <p class="text-muted">GPU Devices Found</p>
            </div>
        `;
    } else {
        html += `
            <div class="summary-card summary-gpu-found">
                <h4><i class="fas fa-search text-muted"></i></h4>
                <h3>0</h3>
                <p class="text-muted">GPU Devices Found</p>
        </div>
        `;
    }
    
    // Throttled count
    if (summary.throttled_count !== undefined && summary.throttled_count !== null) {
        html += `
            <div class="summary-card summary-throttled">
                <h4><i class="fas fa-fire text-danger"></i></h4>
                <h3>${summary.throttled_count}</h3>
                <p class="text-muted">Throttled</p>
            </div>
        `;
    }
    
    // Suspicious count
    if (summary.suspicious_count !== undefined && summary.suspicious_count !== null) {
        html += `
            <div class="summary-card summary-thermally-failed">
                <h4><i class="fas fa-exclamation-triangle text-warning"></i></h4>
                <h3>${summary.suspicious_count}</h3>
                <p class="text-muted">Failed</p>
            </div>
        `;
    }
    
    // Total records processed
    if (summary.total_records !== undefined && summary.total_records !== null) {
        html += `
            <div class="summary-card summary-records">
                <h4><i class="fas fa-chart-line text-info"></i></h4>
                <h3>${summary.total_records.toLocaleString()}</h3>
                <p class="text-muted">Records</p>
            </div>
        `;
    }
    
    summaryCards.innerHTML = html;
    
    // Force flexbox layout after rendering
    summaryCards.style.display = 'flex';
    summaryCards.style.flexDirection = 'row';
    summaryCards.style.flexWrap = 'nowrap';
    summaryCards.style.justifyContent = 'space-between';
    summaryCards.style.gap = '16px';
    summaryCards.style.width = '100%';
    
    // Force each card to stay in flexbox
    const cards = summaryCards.querySelectorAll('.summary-card');
    cards.forEach(card => {
        card.style.flex = '1 1 0';
        card.style.minWidth = '0';
        card.style.maxWidth = 'none';
    });
}

function displayThrottledAlerts(alerts) {
    try {
        console.log('displayThrottledAlerts called with:', alerts);
        
        const container = document.getElementById("throttledAlerts");
        console.log('Container element:', container);
        
        if (!container) {
            console.error('throttledAlerts container not found!');
            return;
        }
        
        // Clear existing content
        container.innerHTML = "";
        
        if (!alerts || alerts.length === 0) {
            console.log('No throttled alerts to display');
            const row = document.createElement("tr");
            row.innerHTML = "<td colspan=\"10\" class=\"text-center text-success\">✅ No throttled GPUs found</td>";
            container.appendChild(row);
            return;
        }
        
        console.log(`Displaying ${alerts.length} throttled alerts`);
        
        alerts.forEach((alert, index) => {
            try {
                console.log(`Processing alert ${index}:`, alert);
                const row = document.createElement("tr");
                row.innerHTML = `
                    <td><strong>${alert.site || "Unknown"}</strong></td>
                    <td><strong>${alert.cluster || "Unknown"}</strong></td>
                    <td><strong>${alert.device}</strong></td>
                    <td><strong class="text-info">${generateDNSName(alert.device)}</strong></td>
                    <td><strong>${alert.gpu_id}</strong></td>
                    <td><strong class="text-danger">${alert.max_temp}&deg;C</strong></td>
                    <td>${formatTimestamp(alert.first_date)}</td>
                    <td>${formatTimestamp(alert.last_date)}</td>
                    <td><strong class="${alert.days_throttled === 1 ? 'text-success' : 'text-danger'}">${alert.days_throttled} day${alert.days_throttled > 1 ? 's' : ''}</strong></td>
                    <td><span class="badge bg-dark">${alert.alert_count || 1}</span></td>
                `;
                container.appendChild(row);
            } catch (alertError) {
                console.error(`Error processing alert ${index}:`, alertError, alert);
            }
        });
    } catch (error) {
        console.error('Error in displayThrottledAlerts:', error);
    }
}
function displayThermallyFailedAlerts(alerts) {
    const container = document.getElementById("thermallyFailedAlerts");
    
    // Clear existing content
    container.innerHTML = "";
    
    console.log("displayThermallyFailedAlerts called with:", alerts);
    
    if (!alerts || alerts.length === 0) {
        const noDataRow = document.createElement("div");
        noDataRow.className = "custom-table-row";
        noDataRow.innerHTML = '<div class="custom-table-cell" style="width: 100%; text-align: center; color: #28a745;">✅ No thermally failed GPUs found</div>';
        container.appendChild(noDataRow);
        container.style.display = "none";
        return;
    }
    
    container.style.display = "block";
    
    alerts.forEach((alert, index) => {
        console.log(`Processing alert ${index}:`, alert);
        
        const row = document.createElement("div");
        row.className = "custom-table-row";
        
        // Create each cell individually to ensure proper structure
        const siteCell = document.createElement("div");
        siteCell.className = "custom-table-cell";
        siteCell.style.width = "7%";
        siteCell.innerHTML = `<strong>${alert.site || "Unknown"}</strong>`;
        
        const clusterCell = document.createElement("div");
        clusterCell.className = "custom-table-cell";
        clusterCell.style.width = "7%";
        clusterCell.innerHTML = `<strong>${alert.cluster || "Unknown"}</strong>`;
        
        const deviceCell = document.createElement("div");
        deviceCell.className = "custom-table-cell";
        deviceCell.style.width = "12%";
        deviceCell.innerHTML = `<strong>${alert.device}</strong>`;
        
        const dnsCell = document.createElement("div");
        dnsCell.className = "custom-table-cell";
        dnsCell.style.width = "15%";
        dnsCell.innerHTML = `<strong class="text-info">${generateDNSName(alert.device)}</strong>`;
        
        const gpuCell = document.createElement("div");
        gpuCell.className = "custom-table-cell";
        gpuCell.style.width = "8%";
        gpuCell.innerHTML = `<strong>${alert.gpu_id}</strong>`;
        
        const tempCell = document.createElement("div");
        tempCell.className = "custom-table-cell";
        tempCell.style.width = "10%";
        tempCell.innerHTML = `<strong class="text-warning">${alert.max_temp}&deg;C</strong>`;
        
        const firstDateCell = document.createElement("div");
        firstDateCell.className = "custom-table-cell";
        firstDateCell.style.width = "12%";
        firstDateCell.innerHTML = formatTimestamp(alert.first_date);
        
        const lastDateCell = document.createElement("div");
        lastDateCell.className = "custom-table-cell";
        lastDateCell.style.width = "12%";
        lastDateCell.innerHTML = formatTimestamp(alert.last_date);
        
        const daysCell = document.createElement("div");
        daysCell.className = "custom-table-cell";
        daysCell.style.width = "10%";
        daysCell.innerHTML = `<strong class="${alert.days_failed === 1 ? 'text-success' : 'text-danger'}">${alert.days_failed} day${alert.days_failed > 1 ? 's' : ''}</strong>`;
        
        const countCell = document.createElement("div");
        countCell.className = "custom-table-cell";
        countCell.style.width = "7%";
        countCell.innerHTML = `<span class="badge bg-dark">${alert.alert_count || 1}</span>`;
        
        // Append all cells to the row
        row.appendChild(siteCell);
        row.appendChild(clusterCell);
        row.appendChild(deviceCell);
        row.appendChild(dnsCell);
        row.appendChild(gpuCell);
        row.appendChild(tempCell);
        row.appendChild(firstDateCell);
        row.appendChild(lastDateCell);
        row.appendChild(daysCell);
        row.appendChild(countCell);
        
        console.log(`Row ${index} created with ${row.children.length} cells`);
        container.appendChild(row);
    });
    
    console.log("Final table HTML:", container.innerHTML);
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
