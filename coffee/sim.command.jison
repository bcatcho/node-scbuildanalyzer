%%

stm
   : sel ARROW trn ENDOFFILE
      { return function (a) { return $1 + a + $3; } }
   ;

trn
   : TRAIN id
      { $$ = $2 }
   ;

sel
   : LPAREN id RPAREN
      { $$ = $2 }
   ;

id
   : ID
   ;
