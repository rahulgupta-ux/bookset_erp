class PendingInvoice {

  final String invoiceId;
  final int amount;
  final bool soldToSchool;

  PendingInvoice({
    required this.invoiceId,
    required this.amount,
    required this.soldToSchool,
  });
}