grammar Lua;

@members {
   public static String grupo="587265";
}

/* Regras sintáticas */

programa : trecho;

trecho : (comando (';')?)* (ultimocomando (';')?)?;

bloco : trecho;

comando : listavar '=' listaexp |
          chamadadefuncao |
          'do' bloco 'end' |
          'repeat' bloco  'until' exp |
          'if' exp 'then' bloco ('elseif' exp 'then' bloco)* ('else' bloco)? 'end' |
          'for' Identificador '=' exp ',' exp (',' exp)?  'do' bloco 'end' |
          'for' listadenomes 'in' listaexp 'do' bloco 'end' |
          'function' nomedafuncao corpodafuncao |
          'local' 'function' Identificador corpodafuncao |
          'local' listadenomes ('=' listaexp)?;

ultimocomando : 'return' (listaexp)? | 'break';

nomedafuncao : Identificador ('.' Identificador)* (':' Identificador)?;

listavar : var (',' var)*;

var : Identificador | expprefixo '[' exp ']' | expprefixo '.' Identificador;

listadenomes : Identificador (',' Identificador)*;

listaexp : (exp ',')* exp;

exp : 'nil' | 'false' | 'true' | Numero | Cadeia | '...' | funcao |
      expprefixo | construtortabela | exp OpBinaria exp | OpUnaria exp;

expprefixo : var | chamadadefuncao | '(' exp ')';

chamadadefuncao : expprefixo args | expprefixo ':' Identificador args;

args : '(' (listaexp)? ')' | construtortabela | Cadeia;

funcao : 'function' corpodafuncao;

corpodafuncao : '(' (listapar)? ')' bloco 'end';

listapar : listadenomes (',' '...')? | '...';

construtortabela : '{' (listadecampos)? '}';

listadecampos : campo (SeparadordeCampos campo)* (SeparadordeCampos)?;

campo : '[' exp ']' '=' exp | Identificador '=' exp | exp;


/* Regras léxicas */

fragment Letra : ('a'..'z'|'A'..'Z');
fragment Digito : ('0'..'9');

Palavra_chave : 'and'    | 'break'  | 'do'   | 'else'     | 'elseif' |
                'end'    | 'false'  | 'for'  | 'function' | 'if'     |
                'in'     | 'local'  | 'nil'  | 'not'      | 'or'     |
                'repeat' | 'return' | 'then' | 'true'     | 'until'  |
                'while';

Operador_logico : 'and' | 'or' | 'not';

Identificador : (Letra|'_') (Letra|Digito|'_')*;

Cadeia : Identificador;

fragment Decimal : ('.' (Digito)+);
fragment Expoente : ( ('e' | 'E') ('-')? (Digito)+ );
fragment Hexadecimal : ('0' 'x' (Digito | ('a'..'f'))+);

Numero : ((Digito)+ (Decimal)? (Expoente)?) | Hexadecimal;

OpUnaria : '-' | 'not' | '#';

OpBinaria : '+' | '-' | '*' | '/' | '^' | '%' | '..' |
            '<' | '<=' | '>' | '>=' | '==' | '~=' |
            'and' | 'or';

SeparadordeCampos : ',' | ';';
