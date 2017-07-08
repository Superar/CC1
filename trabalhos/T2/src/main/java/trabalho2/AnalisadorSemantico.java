package trabalho2;

/**
 * Created by marcio on 08/07/17.
 */
public class AnalisadorSemantico extends LuazinhaBaseListener
{
    PilhaDeTabelas escopos = new PilhaDeTabelas();

    @Override
    public void enterPrograma(LuazinhaParser.ProgramaContext ctx)
    {
        // Escopo global é empilhado e analisador entra em Trecho
        TabelaDeSimbolos escopoGlobal = new TabelaDeSimbolos("global");
        escopos.empilhar(escopoGlobal);
        enterTrecho(ctx.trecho());
        // Ao terminar o programa, o escopo global é desempilhado
        escopos.desempilhar();
    }

    @Override
    public void enterTrecho(LuazinhaParser.TrechoContext ctx)
    {
        // Para cada comando na lista de comandos
        for (LuazinhaParser.ComandoContext comando : ctx.comando())
        {
            enterComando(comando);
        }

        // ultimocomando é opcional, verifica se está presente
        if (ctx.ultimocomando() != null)
        {
            enterUltimocomando(ctx.ultimocomando());
        }
    }

    @Override
    public void enterBloco(LuazinhaParser.BlocoContext ctx)
    {
        enterTrecho(ctx.trecho());
    }

    @Override
    public void enterComando(LuazinhaParser.ComandoContext ctx)
    {
        // Existe uma função sendo declarada
        if (ctx.corpodafuncao() != null)
        {
            // Cria o escopo da função
            TabelaDeSimbolos escopoFuncao;
            // Verifica qual nome deve ser utilizado
            if (ctx.nomedafuncao() != null)
            {
                escopoFuncao = new TabelaDeSimbolos(ctx.nomedafuncao().nome);
            }
            else
            {
                escopoFuncao = new TabelaDeSimbolos(ctx.NOME().getText());
            }
            escopos.empilhar(escopoFuncao);
            enterCorpodafuncao(ctx.corpodafuncao());
            // Ao se terminar a função, o escopo é desempilhado
            escopos.desempilhar();
        }
    }

    @Override
    public void enterCorpodafuncao(LuazinhaParser.CorpodafuncaoContext ctx)
    {
        enterBloco(ctx.bloco());
    }
}