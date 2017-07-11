grammar Luazinha;


@members{
static String grupo = "587265, 595071";
PilhaDeTabelas pilhaDeTabelas = new PilhaDeTabelas();
}


// Empilhamento do escopo global movido para Listener AnalisadorSemantico
programa : trecho
         ;

trecho : (comando ';'?)* (ultimocomando ';'?)?
       ;

bloco : trecho
      ;

// Foram adicionados nomes para os comandos do tipo "for", para identifica-los no Listener
// Tambem foi adicionada o identificador varLocal para uma lista de variaveis locais
// Foi adicionado identificadores para blocos de repeticao do tipo while
// Foi adicionado identificadores para o bloco condicional (if/else)
// Foi adicionado um identificador para o bloco dentro da estrutura de repeat
comando :  listavar '=' listaexp
        |  chamadadefuncao
        |  'do' bloco 'end'
        |  whileToken='while' expWhile=exp 'do' blocoWhile=bloco 'end'
        |  'repeat' blocoRepeat=bloco 'until' exp
        |  'if' expIf=exp 'then' blocoIf=bloco ('elseif' expElseIf+=exp 'then' blocoElseIf+=bloco)* ('else' blocoElse=bloco)? 'end'
        |  for1='for' NOME '=' exp ',' exp (',' exp)? 'do' blocoFor1=bloco 'end'
        |  for2='for' listadenomes 'in' listaexp 'do' blocoFor2=bloco 'end'
        |  'function' nomedafuncao corpodafuncao 
        |  'local' 'function' NOME corpodafuncao
        |  varLocal='local' listadenomes ('=' listaexp)?
        ;

ultimocomando : 'return' (listaexp)? | 'break'
              ;

nomedafuncao returns [ String nome, boolean metodo ]
@init { $metodo = false; }
    : n1=NOME { $nome = $n1.getText(); }
      ('.' n2=NOME { $nome += "." + $n2.getText(); })*
      (':' n3=NOME { $metodo = true; $nome += "." + $n3.getText(); })?
    ;

listavar returns [ List<String> nomes ]
@init { $nomes = new ArrayList<String>(); }
    : v1=var { $nomes.add($v1.nome); }
      (',' v2=var { $nomes.add($v2.nome); }
      )*
    ;

var returns [ String nome, int linha, int coluna ]
    :  NOME { $nome = $NOME.getText(); $linha = $NOME.line; $coluna = $NOME.pos; } 
    |  expprefixo '[' exp ']'
    |  expprefixo '.' NOME
    ;

listadenomes returns [ List<String> nomes ]
@init{ $nomes = new ArrayList<String>(); }
    : n1=NOME { $nomes.add($n1.getText()); }
      (',' n2=NOME { $nomes.add($n2.getText()); } )*
    ;

// Adicao de nomes para a lista de expressoes e a ultima expressao
listaexp : (listaExp+=exp ',')* ultimaExp=exp
         ;

// Adicao de nomes para as expressoes relativas a opbin
exp :  'nil' | 'false' | 'true' | NUMERO | CADEIA | '...' | funcao | 
       expprefixo2 | construtortabela | opbinExp1=exp opbin opBinExp2=exp | opunaria exp
    ;


expprefixo : NOME ( '[' exp ']' | '.' NOME )*
           ;

expprefixo2 : var | chamadadefuncao | '(' exp ')'
           ;

chamadadefuncao :  expprefixo args |
                   expprefixo ':' NOME args
                ;

args :  '(' (listaexp)? ')' | construtortabela | CADEIA 
     ;

funcao : 'function' corpodafuncao
       ;

corpodafuncao : '(' (listapar)? ')' bloco 'end'
              ;

listapar : listadenomes (',' '...')? 
         | '...'
         ;

construtortabela : '{' (listadecampos)? '}'
                 ;

listadecampos : campo (separadordecampos campo)* (separadordecampos)?
              ;

campo : '[' exp ']' '=' exp | NOME '=' exp | exp
      ;

separadordecampos : ',' | ';'
                  ;

opbin : '+' | '-' | '*' | '/' | '^' | '%' | '..' | '<' | 
        '<=' | '>' | '>=' | '==' | '~=' | 'and' | 'or'
      ;

opunaria : '-' | 'not' | '#'
         ;


NOME	:	('a'..'z' | 'A'..'Z' | '_') ('a'..'z' | 'A'..'Z' | '0'..'9' | '_')*;
CADEIA	:	'\'' ~('\n' | '\r' | '\'')* '\'' | '"' ~('\n' | '\r' | '"')* '"';
NUMERO	:	('0'..'9')+ EXPOENTE? | ('0'..'9')+ '.' ('0'..'9')* EXPOENTE?
		| '.' ('0'..'9')+ EXPOENTE?;
fragment
EXPOENTE	:	('e' | 'E') ( '+' | '-')? ('0'..'9')+;

// Adicionado skip para antlr ignorar espacos em branco e comentarios
COMENTARIO
	:	'--' ~('\n' | '\r')* '\r'? '\n' {skip();} -> skip;
WS	:	(' ' | '\t' | '\r' | '\n') {skip();} -> skip;
