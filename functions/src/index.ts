import * as admin from 'firebase-admin';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';

admin.initializeApp();

const firestore = admin.firestore();
const messaging = admin.messaging();

export const notifyIssueStatusChanged = onDocumentUpdated(
  'issues/{issueId}',
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      return;
    }

    const previousStatus = beforeData.status ?? 'Pending';
    const nextStatus = afterData.status ?? 'Pending';

    if (previousStatus === nextStatus) {
      return;
    }

    const userId = afterData.user_id as string | undefined;
    if (!userId) {
      return;
    }

    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return;
    }

    const userData = userDoc.data() ?? {};
    const tokens = Array.isArray(userData.fcm_tokens)
      ? (userData.fcm_tokens as string[]).filter(Boolean)
      : [];

    if (tokens.length === 0) {
      return;
    }

    const category = (afterData.category as string | undefined) ?? 'issue';
    const title = 'StreetLens update';
    const body = `Your ${category} status changed to ${nextStatus}.`;

    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title,
        body,
      },
      data: {
        issueId: event.params.issueId,
        status: nextStatus,
        type: 'status_update',
      },
    });

    const invalidTokens: string[] = [];
    response.responses.forEach((item, index) => {
      if (!item.success) {
        const errorCode = item.error?.code ?? '';
        if (
          errorCode.includes('registration-token-not-registered') ||
          errorCode.includes('invalid-registration-token')
        ) {
          invalidTokens.push(tokens[index]);
        }
      }
    });

    if (invalidTokens.length > 0) {
      await firestore.collection('users').doc(userId).set(
        {
          fcm_tokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
        },
        { merge: true }
      );
    }
  }
);
