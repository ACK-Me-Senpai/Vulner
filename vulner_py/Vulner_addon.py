# Imports

from bs4 import BeautifulSoup
import lxml

# Global vars


# The rest (for now)

with open('nmap_test.xml','r') as f:
    data = f.read()

bs_data = BeautifulSoup(data, 'xml')

result = bs_data.find("host") # Currently only works with 1 host. I need to check how it works with multiple hosts...
results = bs_data.find("port")
result2 = result.find("address")
result3 = result.find("ports")
result4 = result3.find_all("port")
res = dict()
for item in result4:
    #res[item.get('portid')] = res.get(item.get('portid'),[])+[item.parent.parent.get('portid')]
    #res[item.get('portid')] = res.get(item.parent.parent.get('portid'))
    fuckit = item.find("service")
    print(fuckit.get('name'))
    res[item.get('portid')] = res.get(item.get('portid'),[])+[fuckit.get('name'),fuckit.get('product'),fuckit.get('version')]

    #for idonno in prt.find_all("portid"):
        #print(idonno.result4.string)
#for tag in bs_data.find_all('child', {'name':
#print(bs_data.prettify())
#print(result4)
#print(type(result4))
print(res)
