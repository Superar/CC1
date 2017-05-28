grammar Lua;

@members {
   public static String grupo="587265";
}

programa : Palavra_chave | Identificador;


fragment Letra : ('a'..'z'|'A'..'Z');
fragment Numero : ('0'..'9');

Identificador : Letra (Letra|Numero|'_')*;

Palavra_chave : 'and' | 'break' | 'do' | 'else' | 'elseif' |
                'end' | 'false' | 'for' | 'function' | 'if' |
                'in' | 'local' | 'nil' | 'not' | 'or';
