// ATENÇÃO (Etapa 2 — Set 2026): esta função foi encontrada já publicada no
// projeto Supabase mas SEM qualquer chamada correspondente no cliente Flutter
// (nenhum `functions.invoke('oracle', ...)` em lib/). Parece ser um protótipo
// antigo/órfão para um "assistente IA de pesca" (P1 do backlog — ver
// .cursor/rules/proximos-movimentos.mdc — explicitamente marcado como "não
// abrir neste sprint"). Não é a função de marés (essa é `oracle-tides`).
//
// Estava com verify_jwt=false (pública), o que permitia a qualquer pessoa na
// internet consumir créditos OpenAI do projeto sem autenticação nem limite.
// Nesta etapa mudou-se apenas verify_jwt=true (ver supabase/config.toml) — a
// função e o seu comportamento para quem a chamar autenticado mantêm-se
// intactos. Ninguém a chama hoje, por isso este é um fix sem risco de
// regressão. Decisão pendente para o utilizador: apagar definitivamente ou
// manter como base para o P1 IA chat futuro.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SYSTEM_PROMPT = `És o Oráculo da Pesca — um especialista em pesca desportiva ibérica com décadas de experiência.
Tens conhecimento profundo sobre:
- Espécies de peixe de Portugal e Espanha (água doce e salgada)
- Técnicas de pesca: surfcasting, jigging, spinning, pesca à bóia, mosca, carp fishing, etc.
- Rios, estuários, praias e zonas de pesca ibéricas
- Regulamentos e tamanhos mínimos legais em Portugal e Espanha
- Iscas naturais e artificiais adaptadas à pesca ibérica
- Condições meteorológicas, marés e épocas de pesca
- Equipamento: canas, carretilhas, linhas, anzóis, etc.

Responde SEMPRE em português europeu (pt-PT), de forma clara, prática e útil.
Sê directo e concreto. Se não souberes algo com certeza, diz-o claramente.
Máximo 300 palavras por resposta, salvo pedido explícito de resposta longa.`;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", {
      status: 405,
      headers: corsHeaders,
    });
  }

  try {
    const { question } = await req.json();

    if (!question || typeof question !== "string" || question.trim() === "") {
      return new Response(
        JSON.stringify({ error: "O campo 'question' é obrigatório." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!OPENAI_API_KEY) {
      return new Response(
        JSON.stringify({ error: "OPENAI_API_KEY não configurada." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const openaiRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o",
        max_tokens: 600,
        temperature: 0.7,
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: question.trim() },
        ],
      }),
    });

    if (!openaiRes.ok) {
      const err = await openaiRes.text();
      return new Response(
        JSON.stringify({ error: `OpenAI error: ${err}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const data = await openaiRes.json();
    const answer = data.choices?.[0]?.message?.content ?? "";

    return new Response(
      JSON.stringify({ answer }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
