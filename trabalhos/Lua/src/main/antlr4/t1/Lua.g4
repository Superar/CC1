grammar Lua;

@members {
   public static String grupo="587265_e_595071";
}

/* Regras léxicas */

/* Expressões regulares auxiliares para a representação de letras e dígitos. */
fragment Letra : ('a'..'z'|'A'..'Z');
fragment Digito : ('0'..'9');

/* Expressão regular representando todas as palavras-chave da linguagem. */
Palavra_chave : 'and'    | 'break'  | 'do'   | 'else'     | 'elseif' |
                'end'    | 'false'  | 'for'  | 'function' | 'if'     |
                'in'     | 'local'  | 'nil'  | 'not'      | 'or'     |
                'repeat' | 'return' | 'then' | 'true'     | 'until'  |
                'while';

/* Identificadores são qualquer cadeia de letras, dígitos ou sublinhados que
não começam com número. */
Identificador : (Letra|'_') (Letra|Digito|'_')*;

/* Expressão regular para a representação de números.

Decimal indica a presença de  casas decimais representadas por um ponto seguido de dígitos.
Expoente indica a presença de notação científica: 'e' ou 'E' seguido pelo expoente, que pode possuir sinal negativo.
Hexadecimal indica uma representação de número hexadecimal, iniciado por 0x seguido de números hexadecimais, incluindo letras de 'a' a 'f'.

Por fim, Numero une todas as representações:
    Uma sequência de números com parte decimal opcional e expoente opcional, ou;
    Uma representação Hexadecial. */
fragment Decimal : ('.' (Digito)+);
fragment Expoente : ( ('e' | 'E') ('-')? (Digito)+ );
fragment Hexadecimal : ('0' 'x' (Digito | ('a'..'f'))+);
Numero : ((Digito)+ (Decimal)? (Expoente)?) | Hexadecimal;

/* Cadeias são sequências de caracteres entre aspas simples ou aspas duplas.

CadeiaBase indica uma sequência de caracteres quaisquer, sem sequências de escape (\) ou quebras de linha.
Cadeia é uma expressão regular que leva em conta a cadeia base entre aspas simples ou entre aspas duplas.

É importante separar os dois casos, pois não é possível abrir uma cadeia com aspas simples
e fechá-la com aspas duplas ou vice-versa. */
fragment CadeiaBase : (~('\\' | '\n'))*;
Cadeia : ('\'' CadeiaBase '\'') | ('"' CadeiaBase '"');

/* Comentários se iniciam com -- e devem ser ignorados.

ComentarioCurto não aceita quebras de linha, pois termina em uma.
ComentarioLongo se inicia com --[ e termina com ]. Quebras de linha são aceitas.

Comentario une ComentarioLongo e ComentarioCurto.
skip(); indica ao analisador para ignorar o comentário. */
fragment ComentarioCurto : '-' '-' (~('\n'))* '\n';
fragment ComentarioLongo : '-' '-' '[' .*? ']';
Comentario : (ComentarioLongo | ComentarioCurto) -> skip;

/* Espaços em branco devem ser ignorados */
Brancos : [ \n\t\r]+ -> skip;


/* Regras sintáticas */

programa : trecho;

trecho : (comando (';')?)* (ultimocomando (';')?)?;

bloco : trecho;

comando : listavar '=' listaexp |
          /*chamadadefuncao |*/
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

exp : 'nil' | 'false' | 'true' | Digito | Cadeia | '...' | funcao |
      expprefixo | construtortabela | exp opbin exp | opunaria exp;

expprefixo : /*var | chamadadefuncao*/ expprefixo args |
            expprefixo ':' Identificador args | '(' exp ')'; //var aqui estava redundante (eu acho)

//chamadadefuncao : expprefixo args | expprefixo ':' Identificador args; como só é usada aqui, não precisa criar uma nova regra

args : '(' (listaexp)? ')' | construtortabela | Cadeia;

funcao : 'function' corpodafuncao;

corpodafuncao : '(' (listapar)? ')' bloco 'end';

listapar : listadenomes (',' '...')? | '...';

construtortabela : '{' (listadecampos)? '}';

listadecampos : campo (separadordecampos campo)* (separadordecampos)?;

campo : '[' exp ']' '=' exp | Identificador '=' exp | exp;

separadordecampos : ',' | ';';

opbin : '+' | '-' | '*' | '/' | '^' | '%' | '..' |
        '<' | '<=' | '>' | '>=' | '==' | '~=' |
        'and' | 'or';

opunaria : '-' | 'not' | '#';
