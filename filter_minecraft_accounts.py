#!/usr/bin/env python3
"""
Filter script for Minecraft accounts CSV output.
Removes entries that match unwanted criteria such as:
- Cape-related items
- TLauncher accounts
- Gamepass entries (30 days, 1 month, 14 days, etc.)
- "NOT AN ACCOUNT" entries
- Ukraine Region accounts
- Minecraft Legends entries
"""

import csv
import re
import sys
from datetime import datetime

def should_filter_out(title, description):
    """Determine if an entry should be filtered out based on title and description."""
    
    # Convert to lowercase for case-insensitive matching
    title_lower = title.lower()
    desc_lower = description.lower() if description else ""
    
    # Combine title and description for comprehensive search
    combined_text = f"{title_lower} {desc_lower}"
    
    # Filter criteria - return True if should be filtered out
    
    # 1. Cape-related items
    cape_keywords = [
        'cape', 'home cape', 'twitch cape', 'digital cape', 'cape code',
        'blue home cape', 'green home cape', 'red home cape', 'yellow home cape'
    ]
    
    # 2. TLauncher accounts
    tlauncher_keywords = ['tlauncher', 't launcher', 't-launcher']
    
    # 3. Gamepass entries
    gamepass_keywords = [
        'gamepass', 'game pass', '30 days', '1 month', '14 days', '7 days',
        '60 days', '90 days', '180 days', '365 days', '1 year',
        'trial', 'subscription', 'membership', 'rental', 'temporary'
    ]
    
    # 4. NOT AN ACCOUNT entries
    not_account_keywords = ['not an account', 'not account', 'this is not an account']
    
    # 5. Ukraine Region
    ukraine_keywords = ['ukraine', 'ukraine region', 'ukrainian']
    
    # 6. Minecraft Legends
    legends_keywords = ['minecraft legends', 'legends', 'minecraft: legends']
    
    # Additional unwanted keywords
    unwanted_keywords = [
        'skin', 'skin pack', 'texture pack', 'resource pack',
        'mod', 'modpack', 'plugin', 'server', 'realm',
        'gift card', 'giftcode', 'prepaid', 'balance',
        'coins', 'minecoins', 'tokens', 'currency',
        'beta', 'alpha', 'demo', 'test', 'sample'
    ]
    
    all_keywords = (cape_keywords + tlauncher_keywords + gamepass_keywords + 
                   not_account_keywords + ukraine_keywords + legends_keywords + 
                   unwanted_keywords)
    
    # Check if any keyword matches
    for keyword in all_keywords:
        if keyword in combined_text:
            return True
    
    # Additional regex patterns for more complex matches
    patterns = [
        r'\d+\s+days?',  # e.g., "30 days", "14 day"
        r'\d+\s+months?',  # e.g., "1 month", "3 months"
        r'\d+\s+hours?',  # e.g., "24 hours", "48 hour"
        r'\d+\s+weeks?',  # e.g., "2 weeks", "4 week"
        r'\d+\s+years?',  # e.g., "1 year", "2 years"
        r'trial.*access',  # trial access
        r'temporary.*access',  # temporary access
        r'limited.*time',  # limited time
        r'expires.*in',  # expires in
        r'valid.*for',  # valid for
    ]
    
    for pattern in patterns:
        if re.search(pattern, combined_text):
            return True
    
    return False

def filter_minecraft_accounts(input_csv, output_csv=None):
    """Filter the Minecraft accounts CSV file."""
    
    if output_csv is None:
        # Generate output filename if not provided
        timestamp = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
        if 'minecraft_accounts' in input_csv:
            output_csv = input_csv.replace('minecraft_accounts', 'filtered_minecraft_accounts')
        else:
            output_csv = f'filtered_{input_csv}'
    
    print(f"Filtering {input_csv} -> {output_csv}")
    
    filtered_count = 0
    kept_count = 0
    
    with open(input_csv, 'r', encoding='utf-8') as infile, \
         open(output_csv, 'w', encoding='utf-8', newline='') as outfile:
        
        reader = csv.reader(infile)
        writer = csv.writer(outfile)
        
        # Read and write header
        header = next(reader)
        writer.writerow(header)
        
        # Process each row
        for row in reader:
            if len(row) >= 2:  # Ensure we have at least title and description columns
                title = row[1]  # Title is in column 1 (index 1)
                description = row[2] if len(row) > 2 else ""  # Description is in column 2 (index 2)
                
                if should_filter_out(title, description):
                    filtered_count += 1
                else:
                    writer.writerow(row)
                    kept_count += 1
            else:
                # If row doesn't have enough columns, keep it anyway
                writer.writerow(row)
                kept_count += 1
    
    print(f"Filtering complete!")
    print(f"Original entries: {filtered_count + kept_count}")
    print(f"Filtered out: {filtered_count}")
    print(f"Kept: {kept_count}")
    print(f"Filtered data saved to: {output_csv}")
    
    return output_csv

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python filter_minecraft_accounts.py <input_csv> [output_csv]")
        print("Example: python filter_minecraft_accounts.py minecraft_accounts_2023-01-01.csv filtered_accounts.csv")
        sys.exit(1)
    
    input_csv = sys.argv[1]
    output_csv = sys.argv[2] if len(sys.argv) > 2 else None
    
    filter_minecraft_accounts(input_csv, output_csv)