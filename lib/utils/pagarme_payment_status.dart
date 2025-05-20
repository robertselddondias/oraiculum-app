class PagarmePaymentStatus {
  // Status para um pagamento completo
  static const String paid = 'paid';
  static const String authorized = 'authorized';
  static const String captured = 'captured';

  // Status para pagamentos não concluídos ou em processamento
  static const String pending = 'pending';
  static const String processing = 'processing';
  static const String waitingCapture = 'waiting_capture';
  static const String notAuthorized = 'not_authorized';
  static const String partiallyAuthorized = 'partially_authorized';
  static const String partiallyPaid = 'partially_paid';
  static const String pendingRefund = 'pending_refund';
  static const String pendingReview = 'pending_review';

  // Status para transações negadas ou com problema
  static const String refused = 'refused';
  static const String chargedback = 'chargedback';
  static const String failed = 'failed';
  static const String voided = 'voided';
  static const String expired = 'expired';
  static const String canceled = 'canceled';
  static const String refunded = 'refunded';

  // Status para pagamentos com análise antifraude
  static const String underAnalysis = 'under_analysis';
  static const String analyzedAndApproved = 'analyzed_and_approved';
  static const String analyzedAndRejected = 'analyzed_and_rejected';

  // Métodos utilitários
  static bool isSuccessful(String status) {
    return status == paid ||
        status == authorized ||
        status == captured ||
        status == analyzedAndApproved;
  }

  static bool isInProgress(String status) {
    return status == pending ||
        status == processing ||
        status == waitingCapture ||
        status == partiallyPaid ||
        status == pendingReview ||
        status == underAnalysis;
  }

  static bool isFailed(String status) {
    return status == refused ||
        status == chargedback ||
        status == failed ||
        status == voided ||
        status == expired ||
        status == canceled ||
        status == refunded ||
        status == notAuthorized ||
        status == analyzedAndRejected ||
        status == partiallyAuthorized;
  }

  // Método para retornar uma mensagem amigável baseada no status
  static String getStatusMessage(String status) {
    switch (status) {
      case paid:
        return 'Pagamento aprovado';
      case authorized:
        return 'Pagamento autorizado';
      case captured:
        return 'Pagamento capturado';
      case pending:
        return 'Pagamento pendente';
      case processing:
        return 'Processando pagamento';
      case waitingCapture:
        return 'Aguardando captura';
      case notAuthorized:
        return 'Pagamento não autorizado';
      case partiallyAuthorized:
        return 'Pagamento parcialmente autorizado';
      case partiallyPaid:
        return 'Pagamento parcialmente realizado';
      case pendingRefund:
        return 'Reembolso pendente';
      case pendingReview:
        return 'Em análise';
      case refused:
        return 'Pagamento recusado';
      case chargedback:
        return 'Pagamento contestado';
      case failed:
        return 'Falha no pagamento';
      case voided:
        return 'Pagamento anulado';
      case expired:
        return 'Pagamento expirado';
      case canceled:
        return 'Pagamento cancelado';
      case refunded:
        return 'Pagamento reembolsado';
      case underAnalysis:
        return 'Em análise antifraude';
      case analyzedAndApproved:
        return 'Análise aprovada';
      case analyzedAndRejected:
        return 'Análise rejeitada';
      default:
        return 'Status desconhecido: $status';
    }
  }
}