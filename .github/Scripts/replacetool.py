import sys, os
from xml.dom import ValidationErr

def mngerror():
    print("==================================================================")
    print("REPLACETOOL V1")
    print("==================================================================")
    print("")
    print("This tool replace a string value by other inside a document")
    print("")
    print("Call example:")
    print(" >>python REPLACETOOL.py FilePath SearchText ReplaceText")
    print("")
    print("     FilePath:       File path of the file to check.")
    print("     SearchText:     Text to search for inside the file.")
    print("     ReplaceText:    Text to be replaced with.")
    print("")
    print("==================================================================")
    raise SystemExit("")

def main(filepath, searchtxt, replacetxt):
    s = open(filepath).read()
    s = s.replace(searchtxt, replacetxt)
    f = open(filepath, 'w')
    f.write(s)
    f.close()
    print(f"**** REPLACE {searchtxt} SUCCESS. ****")
    print("")
    quit()

if __name__ == "__main__":
    try:
        filePath = sys.argv[1]
    except IndexError:
        print("**** REPLACETOOL ERROR: Missing Path file parameter. ****")
        mngerror()
    try:
        searchTxt = sys.argv[2]
    except IndexError:
        print("**** REPLACETOOL ERROR: Missing Search Text parameter. ****")
        mngerror()
    try:
        replaceTxt = sys.argv[3]
    except IndexError:
        print("**** REPLACETOOL ERROR: Missing Replace text parameter. ****")
        mngerror()

    fileExist = os.path.exists(filePath)
    if fileExist:
        main(filePath, searchTxt, replaceTxt)
    else:
        print("**** REPLACETOOL ERROR: File was not found or not exists. ****")
