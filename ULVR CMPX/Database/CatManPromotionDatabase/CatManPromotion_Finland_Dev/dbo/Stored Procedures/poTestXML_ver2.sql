CREATE PROCEDURE poTestXML_ver2

AS

WITH XMLNAMESPACES('http://www.unece.org/cefact/namespaces/SBDH' as ns0)
SELECT 
'2.2' as 'ns0:StandardBusinessDocumentHeader/ns0:HeaderVersion', 
'EAN.UCC' as 'ns0:StandardBusinessDocumentHeader/ns0:Sender/ns0:Identifier/@Authority', 
'5790000000456' as 'ns0:StandardBusinessDocumentHeader/ns0:Sender/ns0:Identifier',
 (SELECT 1 as 'order'
 FOR XML PATH('Order'), TYPE) as 'ns0:StandardBusinessDocumentHeader/test'
FOR XML PATH('ns0:StandardBusinessDocument')
