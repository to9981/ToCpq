public with sharing class ArchiveAttachmentsToAzureBatchSchedule implements Schedulable {
  public void execute(SchedulableContext sc) {
    ArchiveAttachmentsToAzureBatch batchJob = new ArchiveAttachmentsToAzureBatch();
    Database.executeBatch(batchJob, 100);
  }
}
