grammar Lua;

@members {
   public static String grupo="587265_e_595071_e_619736";
}

/*-------------------- Regras léxicas --------------------*/

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


/*-------------------- Regras sintáticas --------------------*/

/* Um programa é considerado um trecho de código */
programa : trecho;

/* Por sua vez esse trecho de código pode conter 0 ou vários comandos,
terminados ou não por ; */
trecho : (comando (';')?)* (ultimocomando (';')?)?;

bloco : trecho;

/* Lista com todos comandos possíveis de serem executados, dentre esses contém-se:
Atribuição de Variáveis
Chamada de funções
Execuções de comandos
Execuções de comandos condicionais
Execuções de comandos com laços de repetição
Declarações de funções
Entre outros
*/

comando : listavar '=' listaexp |
          chamadadefuncao |
          'do' bloco 'end' |
          'repeat' bloco  'until' exp |
          'if' exp 'then' bloco ('elseif' exp 'then' bloco)* ('else' bloco)? 'end' |
          'for' Identificador '=' exp ',' exp (',' exp)?  'do' bloco 'end' { TabelaDeSimbolos.adicionarSimbolo($Identificador.text,Tipo.VARIAVEL); } |
          'for' listadenomes 'in' listaexp 'do' bloco 'end' |
          'function' nomedafuncao corpodafuncao |
          'local' 'function' Identificador corpodafuncao { TabelaDeSimbolos.adicionarSimbolo($Identificador.text,Tipo.FUNCAO); } |
          'local' listadenomes ('=' listaexp)?;

/* Indica o último comando do trecho, o retorno é opcional. */
ultimocomando : 'return' (listaexp)? | 'break';

/* Definição do nome da função em conjunto com a chamada para adição da mesma, na tabela de símbolos. */
nomedafuncao : Identificador ('.' Identificador)* (':' Identificador)? { TabelaDeSimbolos.adicionarSimbolo($text,Tipo.FUNCAO); } ;

/* Definição da lista de variáveis separadas por vírgula */
listavar : var (',' var)*;

/* Definição de variável em conjunto com a chamada para adição na tablea de símbolos. */
var : Identificador { TabelaDeSimbolos.adicionarSimbolo($Identificador.text,Tipo.VARIAVEL); } |
      expprefixo '[' exp ']' |
      expprefixo '.' Identificador { TabelaDeSimbolos.adicionarSimbolo($Identificador.text,Tipo.VARIAVEL); };

/* Definição da lista de nomes, com chamada para adição na tabela de símbolos. */
listadenomes : Identificador { TabelaDeSimbolos.adicionarSimbolo($Identificador.text,Tipo.VARIAVEL); } (',' Identificador { TabelaDeSimbolos.adicionarSimbolo($Identificador.text,Tipo.VARIAVEL); } )* ;

/* Definição da lista de expressões. */
listaexp : (exp ',')* exp;

/* Produção das expressões com precedência de operadores

As produções das expressões foram quebradas em várias para assim manter a precedência de operadores
desejada conforme orientação. Operadores com maior precedência são "enviados" para os níveis mais
baixos da árvore sintática.

A precedência de operadores segue da menor para a maior. */

/* Operador OR */
exp : exp1 op7 exp | exp1;

/* Operador AND */
exp1 : exp2 op6 exp1 | exp2;

/* Operadores Aritiméticos */
exp2 : exp3 op5 exp2 | exp3;

/* Operador .. */
exp3 : exp4 op4 exp3 | exp4;

/* Operadores Soma / Subtração */
exp4 : exp5 op3 exp4 | exp5;

/* Operadores Multiplicação / Divisão / Módulo */
exp5 : exp6 op2 exp5 | exp6;

/* Operadores Unários */
exp6 : opunaria exp6 | exp7;

/* Operador Potência */
exp7 : exp8 op1 exp7 | exp8;

exp8 : 'nil' | 'false' | 'true' | Numero | Cadeia | '...' | funcao | expprefixo | construtortabela;

/*Regras originalmente recursivas à esquerda:

    var : Identificador | expprefixo '[' exp ']' | expprefixo '.' Identificador;

    expprefixo : var | chamadadefuncao | '(' exp ')';

    chamadadefuncao expprefixo args | expprefixo ':' Identificador args;

A recursividade foi retirada segundo o algoritmo apresentado no site:
    http://www.csd.uwo.ca/~moreno/CS447/Lectures/Syntax.html/node8.html
Primeiramente, substituiu-se todas as produções de var em expprefixo.
Após isso retirou-se a recursividade à esquerda de expprefixo conforme o algoritmo apresentado em aula.
O mesmo procedimento foi realizado com expprefixo e chamadadefuncao.s
*/

/* Definição do prefixo da expressão, com adição da variável utilizada na tabela de símbolos. */
expprefixo : Identificador expprefixo_aux { TabelaDeSimbolos.adicionarSimbolo($Identificador.text,Tipo.VARIAVEL); } |
             chamadadefuncao expprefixo_aux |
             '(' exp ')' expprefixo_aux;

/* Definição do auxiliar do prefixo da expresão. Esta expressão foi criada para a eliminação
da recursividade à esquerda da regra expprefixo. */
expprefixo_aux : '[' exp ']' expprefixo_aux | '.' Identificador expprefixo_aux |
                 /* epsilon */;

/* Definição da chamada de função, regra para realizar a chamada e seus procedimentos. */
chamadadefuncao : Identificador expprefixo_aux args chamadadefuncao_aux { TabelaDeSimbolos.adicionarSimbolo($Identificador.text,Tipo.FUNCAO); } |
                  '(' exp ')' expprefixo_aux args chamadadefuncao_aux |
                  Identificador expprefixo_aux ':' Identificador args chamadadefuncao_aux {TabelaDeSimbolos.adicionarSimbolo($Identificador.text,Tipo.FUNCAO); } |
                  '(' exp ')' expprefixo_aux ':' Identificador args chamadadefuncao_aux;

/* Definição do auxiliar da chamada de função. Esta expressão foi criada para a eliminação
da recursividade à esquerda da regra chamadadefuncao. */
chamadadefuncao_aux : expprefixo_aux args chamadadefuncao_aux |
                      expprefixo_aux ':' Identificador args chamadadefuncao_aux |
                      /* epsilon */;

/* Definição dos argumentos. */
args : '(' (listaexp)? ')' | construtortabela | Cadeia;

/* Definição da função. */
funcao : 'function' corpodafuncao;

/* Definição do corpo da função, que compõe a função definida acima. */
corpodafuncao : '(' (listapar)? ')' bloco 'end';


listapar : listadenomes (',' '...')? | '...';

/* Definição do construtor de tabela. */
construtortabela : '{' (listadecampos)? '}';

/* Definição da lista de campos, com o separador de campos */
listadecampos : campo (separadordecampos campo)* (separadordecampos)?;

/* Definição de campo */
campo : '[' exp ']' '=' exp |
        Identificador '=' exp { TabelaDeSimbolos.adicionarSimbolo($Identificador.text,Tipo.VARIAVEL); } |
        exp;

/* Definição do Separador de Campos */
separadordecampos : ',' | ';';

/* Precedência de Operadores
Segundo o trecho retirado do manual de referência da linguagem:
"A precedência de operadores em Lua segue a tabela abaixo, da menor prioridade para a maior:
or
and
<   >   <=  =>  ~=  ==
..
+   -
*   /   %
not #   - (unario)
^"
*/

// Como os operadores unários têm mesma procedencia, não serão atribuídas prioridades a estes
opunaria : '-' | 'not' | '#';

op1: '^';
op2: '*' | '/' | '%';
op3: '+' | '-';
op4: '..';
op5 : '<' | '>' | '<=' | '=>' | '~=' | '==';
op6: 'and';
op7: 'or';
