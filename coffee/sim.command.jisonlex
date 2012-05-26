digit                       [0-9]
id                          [a-zA-Z][a-zA-Z0-9]*

%%
"select"    return 'SELECT';
"train"     return 'TRAIN';
{digit}+    return 'NATLITERAL';
{id}        return 'ID';
"->"        return 'ARROW';
"("         return 'LPAREN';
")"         return 'RPAREN';
\s+         /* skip whitespace */
<<EOF>>     return 'ENDOFFILE';
