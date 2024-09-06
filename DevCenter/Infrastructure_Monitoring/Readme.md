
1. Access Azure monitor
2. Create Monitor solution(?)
3. Create Log Analytics workspace
4. Create Data collection rule
5. Setup monitored object
    - Create and setup a monitored object : https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-windows-client#create-and-associate-a-monitored-object
        1. Elevate access for Global administrator to all root level access : https://learn.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin?tabs=azure-cli
            a. az login
            b. az rest --method post --url "/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01"
            c. <Remove access> az role assignment delete --assignee username@example.com --role "User Access Administrator" --scope "/"
            d. Assign access, create monitored object, and associate to data collection rule. : https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-windows-client#using-powershell-for-onboarding

6. Setup queries
    - Missing