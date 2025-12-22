/**
 * BACKEND LOGIC SNIPPET (Node.js / Firebase Cloud Functions)
 * 
 * Tarefa 2: Lógica de Atribuição Automática e Visibilidade
 * 
 * Este arquivo contém:
 * 1. Cloud Function para distribuição automática de tickets (Load Balancing).
 * 2. Exemplo de Query Segura para listagem de atendimentos (Visibilidade).
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

/**
 * Lógica de Load Balancing
 * Gatilho: Criação de um novo ticket na coleção 'tickets'.
 */
exports.autoAssignTicket = onDocumentCreated("tickets/{ticketId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const ticketId = event.params.ticketId;
  const ticketData = snapshot.data();

  // Se já tiver assignado (por algum motivo), ignora
  if (ticketData.assigneeId) return;

  try {
    // 1. Seleção de Candidatos: Role HELPER e Status ATIVO
    const helpersSnapshot = await db.collection("users")
      .where("role", "==", "HELPER")
      .where("status", "==", "ACTIVE")
      .get();

    if (helpersSnapshot.empty) {
      console.log(`Nenhum helper ativo encontrado para o ticket ${ticketId}. Atribuindo ao Admin.`);
      // Fallback: Atribuir a um ADMIN padrão ou deixar sem (dependendo da regra de fallback exata)
      // Aqui, vamos atribuir a um ID de admin fixo ou marcar uma flag 'needs_triage'
      await snapshot.ref.update({ assigneeId: "ADMIN_QUEUE", status: "PENDING_TRIAGE" });
      return;
    }

    // 2. Regra do "Menos Ocupado"
    let selectedHelperId = null;
    let minTicketCount = Infinity;

    // Iterar sobre os helpers candidatos
    for (const doc of helpersSnapshot.docs) {
      const helperId = doc.id;

      // Contar tickets ABERTO ou EM ANDAMENTO deste helper
      // Otimização: Usar count() aggregation se disponível, ou query simples
      const activeTicketsQuery = db.collection("tickets")
        .where("assigneeId", "==", helperId)
        .where("status", "in", ["OPEN", "IN_PROGRESS"]);
      
      const countSnapshot = await activeTicketsQuery.count().get();
      const count = countSnapshot.data().count;

      console.log(`Helper ${helperId} tem ${count} tickets ativos.`);

      if (count < minTicketCount) {
        minTicketCount = count;
        selectedHelperId = helperId;
      }
    }

    // 3. Atribuição Final
    if (selectedHelperId) {
      console.log(`Atribuindo ticket ${ticketId} ao helper ${selectedHelperId} (Carga: ${minTicketCount})`);
      await snapshot.ref.update({ 
        assigneeId: selectedHelperId,
        assignedAt: new Date()
      });
    }

  } catch (error) {
    console.error("Erro na distribuição automática de tickets:", error);
  }
});

/**
 * ------------------------------------------------------------------
 * Regra de Visibilidade (Segurança e Query)
 * 
 * O requisito é: "Um helper NÃO pode ver atendimentos que não estejam 
 * atribuídos especificamente ao ID dele (a menos que seja um Admin)."
 * 
 * Isso deve ser implementado em DUAS partes:
 * A. Firestore Security Rules (Backend Security)
 * B. Client Query (Frontend Logic - Snippet demonstrativo)
 * ------------------------------------------------------------------
 */

/*
// A. FIRESTORE SECURITY RULES (firestore.rules)
// Adicione isso ao seu arquivo firestore.rules

match /tickets/{ticketId} {
  allow read: if isOwner(resource.data.userId) || 
                 isAssignedHelper(resource.data.assigneeId) || 
                 isAdmin();
                 
  // Funções auxiliares (Helper functions)
  function isOwner(userId) {
    return request.auth.uid == userId;
  }
  
  function isAssignedHelper(assigneeId) {
    return request.auth.uid == assigneeId;
  }
  
  function isAdmin() {
    // Exemplo: verifica claim customizada ou documento de usuário
    return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "ADMIN";
  }
}
*/

/*
// B. CLIENT QUERY (Exemplo em JavaScript/Dart para o Frontend)
// O filtro deve corresponder à regra de segurança.

async function getMyTickets(currentUser) {
  let query = db.collection('tickets');

  if (currentUser.role === 'ADMIN') {
    // Admin vê tudo
    return query.where('status', 'in', ['OPEN', 'IN_PROGRESS']).get();
  } else {
    // Helper vê APENAS os seus
    return query
      .where('assigneeId', '==', currentUser.uid)
      .where('status', 'in', ['OPEN', 'IN_PROGRESS'])
      .get();
  }
}
*/
