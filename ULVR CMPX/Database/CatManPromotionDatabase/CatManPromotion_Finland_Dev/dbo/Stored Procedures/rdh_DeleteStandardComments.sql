CREATE PROCEDURE rdh_DeleteStandardComments
@CommentID int

AS

DELETE FROM CampaignComments WHERE PK_CampaignCommentID=@CommentID



