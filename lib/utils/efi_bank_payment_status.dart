class EfibankPaymentStatus {
  // Status para um pagamento completo
  static const String approved = 'approved';
  static const String captured = 'captured';
  static const String paid = 'paid';
  static const String completed = 'completed';

  // Status para pagamentos não concluídos ou em processamento
  static const String pending = 'pending';
  static const String processing = 'processing';
  static const String waitingPayment = 'waiting_payment';
  static const String authorized = 'authorized';
  static const String inAnalysis = 'in_analysis';
  static const String preAuthorized = 'pre_authorized';

  // Status para transações negadas ou com problema
  static const String refused = 'refused';
  static const String failed = 'failed';
  static const String chargedback = 'chargedback';
  static const String canceled = 'canceled';
  static const String expired = 'expired';
  static const String refunded = 'refunded';
  static const String voided = 'voided';

  // Métodos utilitários
  static bool isSuccessful(String status) {
    return [
      approved,
      captured,
      paid,
      completed,
      authorized,
    ].contains(status.toLowerCase());
  }

  static bool isInProgress(String status) {
    return [
      pending,
      processing,
      waitingPayment,
      preAuthorized,
      inAnalysis,
    ].contains(status.toLowerCase());
  }

  static bool isFailed(String status) {
    return [
      refused,
      failed,
      chargedback,
      canceled,
      expired,
      refunded,
      voided,
    ].contains(status.toLowerCase());
  }

  // Método para retornar uma mensagem amigável baseada no status
  static String getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case approved:
        return 'Pagamento aprovado';
      case captured:
        return 'Pagamento capturado';
      case paid:
        return 'Pagamento concluído';
      case completed:
        return 'Pagamento concluído';
      case pending:
        return 'Pagamento pendente';
      case processing:
        return 'Processando pagamento';
      case waitingPayment:
        return 'Aguardando pagamento';
      case authorized:
        return 'Pagamento autorizado';
      case inAnalysis:
        return 'Em análise';
      case preAuthorized:
        return 'Pré-autorizado';
      case refused:
        return 'Pagamento recusado';
      case failed:
        return 'Falha no pagamento';
      case chargedback:
        return 'Pagamento contestado';
      case canceled:
        return 'Pagamento cancelado';
      case expired:
        return 'Pagamento expirado';
      case refunded:
        return 'Valor reembolsado';
      case voided:
        return 'Pagamento anulado';
      default:
        return 'Status desconhecido: $status';
    }
  }
}