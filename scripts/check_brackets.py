from pathlib import Path
p=Path('lib/pages/reportes_page.dart')
s=p.read_text()
stack=[]
pairs={ '(':')','[':']','{':'}' }
line=1; col=0
for i,ch in enumerate(s):
    col+=1
    if ch=='\n': line+=1; col=0
    if ch in pairs:
        stack.append((ch,line,col))
    elif ch in [')',']','}']:
        if not stack:
            print('Unmatched closing',ch,'at',line,col)
            break
        last, lline, lcol = stack.pop()
        if pairs[last]!=ch:
            print('MISMATCH: opened',last,'at',lline,lcol,'but closed by',ch,'at',line,col)
            # print stack tail for context
            print('Stack tail (last 10):', stack[-10:])
            # print surrounding text
            start = max(0, i-40)
            context = s[start:start+120]
            print('Context around error:\n', repr(context))
            break
else:
    if stack:
        last, lline, lcol = stack[-1]
        print('Unclosed opener', last, 'opened at', lline, lcol)
    else:
        print('All balanced')
