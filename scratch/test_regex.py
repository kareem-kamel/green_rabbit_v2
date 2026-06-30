import re

def test():
    text = "Here is some text ##1. and ##2. and also the [1][3][1]if and stuff like that [2](http://url)"
    
    # fix headers
    text = re.sub(r'(?m)^(\s*)(#{1,6})(?=[^\s#])', r'\1\2 ', text)
    # also test inline ## just in case they don't start at beginning of line
    text = re.sub(r'(#{1,6})(?=[^\s#])', r'\1 ', text)
    
    # fix citations
    text = re.sub(r'(\[\d+\])(?!\()', r' **\1** ', text)
    
    print(text)

test()
