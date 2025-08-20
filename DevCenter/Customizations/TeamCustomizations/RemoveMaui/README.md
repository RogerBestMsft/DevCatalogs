# Remove MAUI Workloads - Dev Box Team Customization

This customization removes all .NET Multi-platform App UI (MAUI) workloads from Visual Studio installations on a Dev Box.

## What it does

This customization identifies and removes the following MAUI-related workloads and components:

- `Microsoft.VisualStudio.Workload.NetCrossPlat` - .NET Multi-platform App UI development workload
- `Microsoft.VisualStudio.Component.MonoDebugger` - Mono debugger component
- `Microsoft.VisualStudio.ComponentGroup.Maui.All` - All MAUI components
- `Microsoft.VisualStudio.ComponentGroup.Maui.Blazor` - MAUI Blazor components
- `Microsoft.VisualStudio.ComponentGroup.Maui.Windows` - MAUI Windows components
- `Microsoft.VisualStudio.ComponentGroup.Maui.Android` - MAUI Android components
- `Microsoft.VisualStudio.ComponentGroup.Maui.iOS` - MAUI iOS components
- `Microsoft.VisualStudio.ComponentGroup.Maui.MacCatalyst` - MAUI Mac Catalyst components
- `Microsoft.Component.NetFX.Native` - .NET Native component
- `Microsoft.VisualStudio.Component.Graphics.Tools` - Graphics tools component

## How it works

1. **Elevation**: The task runs with `runElevated: true` to ensure proper permissions for Visual Studio modification
2. **Discovery**: Uses `vswhere.exe` to find all Visual Studio installations
3. **Identification**: Checks each installation for MAUI workloads using the `-requires` parameter
4. **Removal**: Uses the Visual Studio Installer CLI to remove identified MAUI workloads
5. **Logging**: Provides detailed output about the removal process

## Elevation and Permissions

This customization uses `runElevated: true` in the task definition to ensure it runs with the necessary administrative privileges required by the Visual Studio Installer CLI. Dev Box customizations with this setting will automatically run in an elevated context.

## Base Image

This customization is designed for the base image:
`microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2`

## Usage

1. Deploy this `imageDefinition.yaml` file as a team customization in your Azure Dev Center
2. Associate it with your Dev Box pool
3. Create new Dev Boxes or reimage existing ones to apply the customization

## Validation

To validate this customization file before deployment, run:

```powershell
devbox customizations validate-tasks --filePath "imageDefinition.yaml"
```

## Documentation

For more information about Dev Box team customizations, visit:
https://learn.microsoft.com/en-us/azure/dev-box/concept-what-are-team-customizations

## Notes

- The script runs silently (`--quiet` flag) to avoid user interaction
- The script waits for completion (`--wait` flag) before proceeding
- If no MAUI workloads are found, the script will complete successfully without making changes
- All operations are logged with color-coded output for easy monitoring
