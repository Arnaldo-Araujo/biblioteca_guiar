/**
 * CLOUD FUNCTIONS (Backend Code)
 * 
 * Arquivo: api_churches.js
 * Objetivo: Endpoints para gerenciamento de Igrejas (Multi-tenancy).
 * 
 * Estrutura:
 * - Middleware de Autenticação e Verificação de Role (SUPER_ADMIN).
 * - CRUD de Igrejas (Create, Update, Delete).
 * 
 * Deploy:
 * Copie este código para o seu 'index.js' do Cloud Functions.
 */

const { onRequest } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

const db = getFirestore();

// Middleware simulado (em funcoes V2 onRequest a gente trata dentro da funcao ou usa Express)
// Aqui vamos usar um Wrapper pattern para simplificar.

async function checkSuperAdmin(req, res) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).send('Unauthorized: No token provided');
        return null;
    }

    const token = authHeader.split('Bearer ')[1];
    try {
        const decodedToken = await getAuth().verifyIdToken(token);
        const userId = decodedToken.uid;

        // Verificar role no Firestore
        const userDoc = await db.collection('users').doc(userId).get();
        if (!userDoc.exists || userDoc.data().role !== 'SUPER_ADMIN') {
            res.status(403).send('Forbidden: Requires SUPER_ADMIN role');
            return null;
        }

        return userId; // Sucesso
    } catch (error) {
        res.status(401).send('Unauthorized: Invalid token');
        return null;
    }
}

/**
 * 1. CRIAR IGREJA (POST)
 */
exports.createChurch = onRequest(async (req, res) => {
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

    const userId = await checkSuperAdmin(req, res);
    if (!userId) return; // Erro já enviado pelo middleware

    const { name, city, state, address } = req.body;
    if (!name || !city || !state) {
        return res.status(400).send('Missing required fields (name, city, state)');
    }

    try {
        const newChurchRef = db.collection('churches').doc();
        const churchData = {
            id: newChurchRef.id,
            name,
            city,
            state,
            address: address || '',
            createdAt: new Date(),
            createdBy: userId,
            active: true
        };

        await newChurchRef.set(churchData);
        res.status(201).json({ message: 'Church created successfully', id: newChurchRef.id });
    } catch (e) {
        res.status(500).send(`Internal Server Error: ${e.message}`);
    }
});

/**
 * 2. EDITAR IGREJA (PUT)
 * Endpoint: /updateChurch?id={churchId}
 */
exports.updateChurch = onRequest(async (req, res) => {
    if (req.method !== 'PUT') return res.status(405).send('Method Not Allowed');

    const userId = await checkSuperAdmin(req, res);
    if (!userId) return;

    const churchId = req.query.id;
    if (!churchId) return res.status(400).send('Missing church ID query parameter');

    const updateData = req.body; // Campos a atualizar

    try {
        await db.collection('churches').doc(churchId).update({
            ...updateData,
            updatedAt: new Date(),
            updatedBy: userId
        });
        res.status(200).json({ message: 'Church updated successfully' });
    } catch (e) {
        res.status(500).send(`Error updating church: ${e.message}`);
    }
});

/**
 * 3. DELETAR IGREJA (DELETE - Soft Delete)
 * Endpoint: /deleteChurch?id={churchId}
 */
exports.deleteChurch = onRequest(async (req, res) => {
    if (req.method !== 'DELETE') return res.status(405).send('Method Not Allowed');

    const userId = await checkSuperAdmin(req, res);
    if (!userId) return;

    const churchId = req.query.id;

    try {
        // Soft Delete: Marca como active = false
        await db.collection('churches').doc(churchId).update({
            active: false,
            deletedAt: new Date(),
            deletedBy: userId
        });
        res.status(200).json({ message: 'Church soft-deleted successfully' });
    } catch (e) {
        res.status(500).send(`Error deleting church: ${e.message}`);
    }
});
