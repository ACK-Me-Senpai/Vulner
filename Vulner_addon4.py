from bs4 import BeautifulSoup
import sys
import os
import lxml # Temp
from time import sleep

basic_out = str()
expanded_out = str()

try:
    filename = sys.argv[1]
    if os.path.exists(filename):
        print("This file exists!")
        split = os.path.splitext(filename)
        if split[-1].lower() == ".xml":
            print("This file is xml!")
            basic_out = str(split[0])+"_basic.txt"
            expanded_out = str(split[0])+"_expanded.txt"
        else:
            print("Only xml files are allowed!")
            exit()
    else:
        print("This file does not exist!")
        exit()
except IndexError:
    print("No file was given!")
    exit()
print(f"Given file name = {filename}")

with open(filename,'r') as file:
    data = file.read()
bs_data = BeautifulSoup(data,'xml')

hosts_res = dict()

#basic = open(basic_out, 'a')

results = bs_data.find_all("host")
for hst in results:
    vulners = dict()
    #disc_vulns = dict()
    hst2 = hst.find("address")
    ip_addr = hst2.get('addr')
    hst3 = hst.find("ports")
    if hst3 == None:
        continue
    hst4 = hst.find_all("port")
    for port in hst4:
        port_num = port.get('portid')
        service = port.find('service')
        try:
            service_name = service.get('name')
        except AttributeError:
            service_name = "N/A"
        try:
            service_prod = service.get('product')
        except AttributeError:
            service_prod = "N/A"
        try:
            service_ver = service.get('version')
        except AttributeError:
            service_ver = "N/A"
        counter = 0
        base_dict = dict()
        disc_vulns = list()
        scripts = port.find_all("script")
        for script in scripts:
            word_bank = ["Couldn't find","NOT VULNERABLE", "NOT VULNERABLE"]
            keyword = "vulnerable"
            #tmp1 = "{} | {} | {}\n"
            #tmp2 = "{}\n"
            # Check if one of the negative key words ("word_bank") exists inside of the script output
            if word_bank[0] in script.get('output') or word_bank[1] in script.get('output'):
                #counter = 0
                continue # If they exist, ignore them.
            elif keyword in script.get('output').lower(): # if the output contains the word "vulnerable", print it. We want it!
                counter += 1
                disc_vulns.append(script.get('output'))
                #print(f"{hst2.get('addr')} | {port.get('portid')} | {script.get('id')}")
                #print(script.get('output'))
            else: # In any rare case, it's always good to have a backup option.
                #counter = 0
                continue
        #base_dict[port_num] = base_dict.get(port_num,[])+[service_name,service_prod,service_ver,counter]
        base_dict[port_num] = base_dict.get(port_num,[])+[service_name,service_prod,service_ver,disc_vulns]
        hosts_res[ip_addr] = hosts_res.get(ip_addr,[])+[base_dict]

#basic.close()

#for i in hosts_res.keys():
#    print(f"\n\n{hosts_res[i]}\n")

basic = open(basic_out,"w")

#template1="\033[1m{:<17}|{:<7}|{:<15}|{:<47}|{}\033[0m"
#template2="{:<17}|{:<7}|{:<15}|{:<47}|{}"
template1="\033[1m{:<17}|{:<7}|{:<15}|{:<47}|{}\033[0m\n"
template2="{:<17}|{:<7}|{:<15}|{:<47}|{}\n"
header = template1.format("IP","Port","Service","Product // Version","NSEs Triggered")
#print(header)
basic.write(header)
basic.close()

basic = open(basic_out, "a")

for ip in hosts_res.keys():
    for ports in hosts_res[ip]:
        for port in ports.keys():
            data = ports[port]
            service = data[0]
            product = str(data[1])
            version = str(data[2])
            has_vulns = len(data[3])
            line = template2.format(ip,port,service,str(product+" // "+version),has_vulns)
            #print(line)
            basic.write(line)

basic.close()
# NOTES:
# Basic out format = ip | port | service | product // version | # of vulns
# Expanded out format = how can I make the file greppable / easy to read for the end user? I still need to have the info saved and maybe even displayed...
# I can maybe save the full results in a file away from the eye, and only display the nse that found the vulnerability?
# I can also do this by saving the entire string in base64 and have it be decoded when the user calls for it? I can also create an sql db file so the output will be saved with the rest of the info, but then the end user won't be able to access this information easily (they will need to rely on other programs, not ideal).
# I CAN save the output as it is if I append it to the list and then add the list to the dict, but it is not pretty to look at... But I can probably make it so if the end user wants to view the data from within the main script, he will be able to. Now all I need to figure out is how do I parse python dictionaries in bash...?
# Also, I still need to figure out how much python can I include in this project. Let's hope for the best!

# In conclusion - basic will be the current output (with number of NSEs) and expanded will just be a print of all the items in the dictionary as is!
