#!/usr/bin/env python3
"""
Generate screen configuration file for KWin multi-monitor window switcher.

This script reads monitor information from xrandr and creates a configuration
file that the KWin window switcher can use to position dialogs on all monitors.

Output format: width,height,x,y;width,height,x,y
Example: 1920,1080,0,0;1920,1080,1920,0
"""

import subprocess
import re
import sys
import os

def run_xrandr():
    """Run xrandr and return the output."""
    try:
        result = subprocess.run(['xrandr', '--listmonitors'], 
                              capture_output=True, text=True, check=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error running xrandr: {e}", file=sys.stderr)
        return None
    except FileNotFoundError:
        print("xrandr not found. Please install xrandr.", file=sys.stderr)
        return None

def parse_monitors(xrandr_output):
    """
    Parse xrandr --listmonitors output and extract monitor information.
    
    Expected format:
    Monitors: 2
     0: +*HDMI-1 1920/309x1080/173+0+0  HDMI-1
     1: +DP-1 1920/309x1080/173+1920+0  DP-1
    """
    monitors = []
    
    # Look for monitor lines that start with a number
    monitor_pattern = r'^\s*(\d+):\s+\+?\*?(\S+)\s+(\d+)/\d+x(\d+)/\d+\+(\d+)\+(\d+)'
    
    for line in xrandr_output.split('\n'):
        match = re.match(monitor_pattern, line)
        if match:
            index = int(match.group(1))
            name = match.group(2)
            width = int(match.group(3))
            height = int(match.group(4))
            x = int(match.group(5))
            y = int(match.group(6))
            
            monitors.append({
                'index': index,
                'name': name,
                'width': width,
                'height': height,
                'x': x,
                'y': y
            })
            
    return monitors

def format_config(monitors):
    """Format monitors into the config file format."""
    if not monitors:
        return ""
    
    # Sort by index to ensure consistent ordering
    monitors.sort(key=lambda m: m['index'])
    
    config_parts = []
    for monitor in monitors:
        config_parts.append(f"{monitor['width']},{monitor['height']},{monitor['x']},{monitor['y']}")
    
    return ';'.join(config_parts)

def write_config_file(config_string, output_path="/tmp/kwin-screens.txt"):
    """Write the configuration to a file."""
    try:
        with open(output_path, 'w') as f:
            f.write(config_string)
        return True
    except IOError as e:
        print(f"Error writing config file: {e}", file=sys.stderr)
        return False

def main():
    """Main function."""
    print("KWin Multi-Monitor Window Switcher Configuration Generator")
    print("=" * 60)
    
    # Run xrandr
    print("Running xrandr --listmonitors...")
    xrandr_output = run_xrandr()
    if not xrandr_output:
        sys.exit(1)
    
    print("Raw xrandr output:")
    print(xrandr_output)
    print("-" * 40)
    
    # Parse monitors
    monitors = parse_monitors(xrandr_output)
    if not monitors:
        print("No monitors found in xrandr output.", file=sys.stderr)
        sys.exit(1)
    
    print(f"Found {len(monitors)} monitor(s):")
    for monitor in monitors:
        print(f"  {monitor['index']}: {monitor['name']} - "
              f"{monitor['width']}x{monitor['height']} at ({monitor['x']},{monitor['y']})")
    
    # Generate config
    config = format_config(monitors)
    print(f"\nGenerated config: {config}")
    
    # Write to file
    output_path = "/tmp/kwin-screens.txt"
    if write_config_file(config, output_path):
        print(f"\nConfiguration written to: {output_path}")
        print("\nTo test the window switcher:")
        print("1. Make sure QML_XHR_ALLOW_FILE_READ=1 is set")
        print("2. Press Alt+Tab to see the multi-monitor window switcher")
        print("\nTo update the configuration after changing monitors:")
        print(f"  python3 {__file__}")
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()