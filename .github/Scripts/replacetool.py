import sys

filetosearch = sys.argv[1]
texttoreplace = sys.argv[2]
texttoinsert = sys.argv[3]

# print(filetosearch)
# print(texttoreplace)
# print(texttoinsert)

s = open(filetosearch).read()
s = s.replace(texttoreplace, texttoinsert)
f = open(filetosearch, 'w')
f.write(s)
f.close()
quit()
