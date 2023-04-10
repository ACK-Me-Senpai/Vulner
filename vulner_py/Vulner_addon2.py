# Imports

from bs4 import BeautifulSoup
import lxml

# Global vars


# The rest (for now)

with open('nmap_test2.xml','r') as f:
    data = f.read()

bs_data = BeautifulSoup(data, 'xml')

result = bs_data.find("host") # Currently only works with 1 host. I need to check how it works with multiple hosts...
hosts_res = dict()

results = bs_data.find_all("host")
#print(results)
for hst in results:
    hst2 = hst.find("address")
    #print(hst2)
    hst3 = hst.find("ports")
    #print(hst3)
    if hst3 == None:
        continue
    hst4 = hst.find_all("port")
    #print(hst4)
    killme = dict()
    for cuck in hst4:
        #print(cuck)
        #try:
        #killme = dict()
        fuckyou = cuck.find("service")
        killme[cuck.get('portid')] = killme.get(cuck.get('portid'),[])+[fuckyou.get('name'),fuckyou.get('product'),fuckyou.get('version')]
        #print(killme)
        #except AttributeError:
            #continue
    #print(killme)
    hosts_res[hst2.get("addr")] = hosts_res.get(hst2.get("addr"),[])+[killme]

print(hosts_res)
for i in hosts_res.keys():
    print(i)
    print(f"\n\n{hosts_res[i]}\n\n")
    if hosts_res[i] == None:
        print(True)
    else:
        print(False)

#result2 = result.find("address")
#result3 = result.find("ports")
#result4 = result3.find_all("port")
#res = dict()
#for item in result4:
    #res[item.get('portid')] = res.get(item.get('portid'),[])+[item.parent.parent.get('portid')]
    #res[item.get('portid')] = res.get(item.parent.parent.get('portid'))
    #fuckit = item.find("service")
    #print(fuckit.get('name'))
    #res[item.get('portid')] = res.get(item.get('portid'),[])+[fuckit.get('name'),fuckit.get('product'),fuckit.get('version')]

    #for idonno in prt.find_all("portid"):
        #print(idonno.result4.string)
#for tag in bs_data.find_all('child', {'name':
#print(bs_data.prettify())
#print(result4)
#print(type(result4))
#print(res)
