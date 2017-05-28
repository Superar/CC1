grammar Lua;

@members {
   public static String grupo="587265";
}

programa : Identificador;

Identificador : ('a'..'z')+;
