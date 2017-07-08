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
        // Escopo global e empilhado e analisador entra em Trecho
        TabelaDeSimbolos escopoGlobal = new TabelaDeSimbolos("global");
        escopos.empilhar(escopoGlobal);
        enterTrecho(ctx.trecho());
        // Ao terminar o programa, o escopo global e desempilhado
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

        // ultimocomando e opcional, verifica se esta presente
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

        // Existem variaveis sendo atribuidas
        if (ctx.listavar() != null)
        {
            // Adiciona todas as variáveis em listavar como variaveis
            for (String nome : ctx.listavar().nomes)
            {
                // Variavel so e criada se nao existir
                if (!escopos.topo().existeSimbolo(nome))
                {
                    escopos.topo().adicionarSimbolo(nome, "variavel");
                }
            }
        }

        // TODO: Adicionar escopo para comandor de loop 'for'

        // Existe uma funcao sendo declarada
        else if (ctx.corpodafuncao() != null)
        {
            // Cria o escopo da funcao
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
            // Ao se terminar a funcao, o escopo e desempilhado
            escopos.desempilhar();
        }
    }

    @Override
    public void enterCorpodafuncao(LuazinhaParser.CorpodafuncaoContext ctx)
    {
        // Funcao possui parametros que devem ser inseridos na tabela de simbolos
        if (ctx.listapar() != null)
        {
            enterListapar(ctx.listapar());
        }

        enterBloco(ctx.bloco());
    }

    @Override
    public void enterListapar(LuazinhaParser.ListaparContext ctx)
    {
        // Se existirem parametros no formato de nomes, serao inseridos a tabela
        if (ctx.listadenomes() != null)
        {
            for (String nome : ctx.listadenomes().nomes)
            {
                if (!escopos.topo().existeSimbolo(nome))
                {
                    escopos.topo().adicionarSimbolo(nome, "parametro");
                }
            }
        }
    }
}