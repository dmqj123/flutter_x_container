# FlutterX Container App Development Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [App Structure](#app-structure)
4. [Manifest File](#manifest-file)
5. [User Interface (XML)](#user-interface-xml)
6. [Permissions](#permissions)
7. [App Installation](#app-installation)
8. [Best Practices](#best-practices)

## Introduction

The FlutterX Container is a cross-platform lightweight app container that allows developers to create and run apps using a custom XML-based interface system. This guide will help you develop applications that can run within the FlutterX Container.

## Getting Started

To develop an app for FlutterX Container, you need to create a structured app package that includes:

1. `manifest.json` - Metadata about your app
2. `interface.xml` - User interface definition
3. `main.dart` - App logic (optional but recommended)
4. `assets/` - App resources (icons, images, etc.)

## App Structure

A typical FlutterX app follows this structure:

```
my_app/
├── manifest.json
├── interface.xml
├── main.dart
└── assets/
    ├── icon.png
    └── other_resources/
```

### Required Files

1. **manifest.json** - Contains app metadata and configuration
2. **interface.xml** - Defines the user interface using XML
3. **icon.png** - App icon (recommended 128x128 or higher)

### Optional Files
- **main.dart** - Contains app logic (if any)
- Additional assets and resources

## Manifest File

The `manifest.json` file contains essential information about your app:

```json
{
  "packageName": "com.yourcompany.yourapp",
  "name": "Your App Name",
  "version": "1.0.0",
  "iconPath": "assets/icon.png",
  "permissions": [
    {
      "name": "basic_functionality",
      "level": "PermissionLevel.normal",
      "description": "Basic app functionality"
    }
  ],
  "interfacePath": "interface.xml",
  "codePath": "main.dart",
  "packagePath": "",
  "isSystemApp": false
}
```

### Manifest Fields

| Field | Type | Description |
|-------|------|-------------|
| `packageName` | String | Unique identifier for your app (e.g., com.yourcompany.yourapp) |
| `name` | String | Display name of your app |
| `version` | String | Version number of your app |
| `iconPath` | String | Path to your app icon relative to package root |
| `permissions` | Array | List of requested permissions |
| `interfacePath` | String | Path to your XML interface file |
| `codePath` | String | Path to your Dart code file |
| `packagePath` | String | Path to the original package file (usually empty for new apps) |
| `isSystemApp` | Boolean | Whether this is a system app (grants all permissions) |

## User Interface (XML)

FlutterX uses a custom XML-based UI system. The interface is defined in the `interface.xml` file.

### Supported XML Elements

#### `container`
A container element that can hold other widgets with various styling options.

Attributes:
- `padding`: EdgeInsets for internal padding
- `margin`: EdgeInsets for external margin
- `width`: Width of the container
- `height`: Height of the container
- `color`: Background color

```xml
<container padding="16,16,16,16" margin="10,10,10,10" color="lightblue">
  <!-- Child elements -->
</container>
```

#### `column`
Arranges child elements vertically.

Attributes:
- `mainAxisAlignment`: How children should be placed along the main axis (start, end, center, space_between, space_around, space_evenly)
- `crossAxisAlignment`: How children should be placed along the cross axis (start, end, center, stretch, baseline)

```xml
<column mainAxisAlignment="center" crossAxisAlignment="center">
  <!-- Child elements -->
</column>
```

#### `row`
Arranges child elements horizontally.

Attributes:
- `mainAxisAlignment`: How children should be placed along the main axis
- `crossAxisAlignment`: How children should be placed along the cross axis

```xml
<row mainAxisAlignment="space_evenly">
  <button>Button 1</button>
  <button>Button 2</button>
</row>
```

#### `text`
Displays text with styling options.

Attributes:
- `size`: Font size
- `color`: Text color
- `weight`: Font weight (normal, bold, w100-w900)
- `textAlign`: Text alignment

```xml
<text size="18" color="blue" weight="bold">Hello World</text>
```

#### `button`
Interactive button element.

Attributes:
- `onPressed`: Action to execute when pressed (required for functionality)

```xml
<button onPressed="buttonClicked">Click Me!</button>
```

#### `icon_button`
Button with an icon.

Attributes:
- `icon`: Icon name (add, remove, delete, edit, save, home, settings, info, close)
- `onPressed`: Action to execute when pressed

```xml
<icon_button icon="home" onPressed="homePressed" />
```

#### `image`
Displays an image from assets.

Attributes:
- `src`: Path to the image file

```xml
<image src="assets/image.png" />
```

#### `divider`
A visual separator line.

```xml
<divider />
```

#### `card`
A container with elevation effect.

```xml
<card>
  <!-- Child elements -->
</card>
```

#### `list_tile`
Represents a single row in a list with optional title and subtitle.

```xml
<list_tile>
  <title>Title Text</title>
  <subtitle>Subtitle Text</subtitle>
</list_tile>
```

### Padding and Margin Format

Padding and margin values use the format:
- Single value: `"10"` - All sides
- Four values: `"10,5,10,5"` - Top, Right, Bottom, Left (like CSS)

### Color Specification

Colors can be specified as:
- Named colors: `red`, `blue`, `green`, `yellow`, `black`, `white`, `grey/gray`, `transparent`
- Hex colors: `#FF0000` (6-digit) or `#FFFF0000` (8-digit with alpha)

### Text Weight Values

- `w100` to `w900`: Specific font weights
- `normal`: Regular font weight
- `bold`: Bold font weight

## Permissions

Apps can request permissions to access certain system features. Currently supported permissions include:

### Normal Permissions
- `basic_functionality`: Basic app functionality
- `camera`: Access camera to take photos
- `location`: Access device location
- `storage_read`: Read files from device storage
- `storage_write`: Write files to device storage
- `microphone`: Access microphone for audio recording
- `nfc`: Access NFC functionality
- `bluetooth`: Access Bluetooth functionality

### Administrator Permissions
- `system_settings`: Change system settings
- `device_admin`: Perform device administration tasks
- `window_management`: Manage window properties (desktop)
- `mouse_position`: Access mouse position (desktop)

### Declaring Permissions

Permissions are declared in the manifest.json file:

```json
{
  "permissions": [
    {
      "name": "camera",
      "level": "PermissionLevel.normal",
      "description": "Access camera to take photos"
    }
  ]
}
```

## App Installation

Apps are packaged as `.fxc` files (FlutterX Container packages). To install an app:

1. Build your app package (`.fxc` file)
2. In the FlutterX Container, tap the "+" button
3. Enter the path to your `.fxc` file
4. Tap "Install"

## Best Practices

1. **Unique Package Names**: Use reverse domain notation for your package names (e.g., com.yourcompany.yourapp)

2. **Meaningful Action Names**: When defining button `onPressed` attributes, use clear, descriptive action names

3. **Responsive Design**: Use appropriate padding and margin values to ensure your app looks good on different screen sizes

4. **Error Handling**: Make sure your XML is well-formed and all referenced assets exist

5. **Performance**: Keep your UI simple and avoid excessive nesting of elements

6. **Accessibility**: Use appropriate text sizes and color contrasts

## Example App

Here's a complete example of a simple counter app:

### manifest.json
```json
{
  "packageName": "com.example.counter",
  "name": "Counter App",
  "version": "1.0.0",
  "iconPath": "assets/icon.png",
  "permissions": [
    {
      "name": "basic_functionality",
      "level": "PermissionLevel.normal",
      "description": "Basic app functionality"
    }
  ],
  "interfacePath": "interface.xml",
  "codePath": "main.dart",
  "packagePath": "",
  "isSystemApp": false
}
```

### interface.xml
```xml
<column mainAxisAlignment="center" crossAxisAlignment="center">
  <text size="24" weight="bold">Counter App</text>
  <container margin="20,20,20,20">
    <text id="countDisplay" size="48" weight="bold" color="blue">0</text>
  </container>
  <row>
    <button onPressed="decrementCounter">-</button>
    <button onPressed="incrementCounter">+</button>
  </row>
</column>
```

## Known Limitations

- Actions defined in XML (via `onPressed`) currently only print to the console and don't execute any actual functionality
- Complex UI interactions may not work as expected
- Advanced Flutter widgets are not available through the XML interface system

## Troubleshooting

1. **Grayed-out buttons**: Make sure all buttons have an `onPressed` attribute
2. **Missing assets**: Verify that all referenced assets exist in the correct paths
3. **App not appearing**: Check that the manifest.json is valid and properly formatted
4. **Permission errors**: Ensure requested permissions are valid and declared correctly in the manifest

## Next Steps

To get started developing your first FlutterX app:

1. Create a new directory for your app
2. Add the required files (manifest.json, interface.xml, assets/icon.png)
3. Define your UI in interface.xml
4. Package your app as a `.fxc` file
5. Install and test in the FlutterX Container