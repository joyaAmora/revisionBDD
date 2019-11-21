-- 2a
UPDATE COMMANDE
SET totalSansTx = totalSansTx + 
    (select sum(QCOM*PRIX) 
    FROM DETAIL d, PRODUIT p
    WHERE d.NPRO = p.NPRO AND NCOM = COMMANDE.NCOM
    GROUP BY NCOM)
WHERE EXISTS (SELECT * FROM DETAIL WHERE NCOM = COMMANDE. NCOM);

-- 2b
UPDATE CLIENT
SET COMPTE = COMPTE +
    (select sum(totalSansTx+(totalSansTx*(TPS+TVQ)))
    FROM COMMANDE c, TAXE t
    WHERE c.codeTx = t.codeTx AND payee = FALSE
    AND NCLI = CLIENT.NCLI)
WHERE EXISTS (select * from COMMANDE WHERE NCLI = CLIENT.NCLI AND payee = false);


-- 3a
SELECT CLIENT.NCLI, NOM, LOCALITE, SUM(totalSansTx*(TPS+TVQ)) as total
FROM CLIENT c, COMMANDE cm, TAXE t
WHERE cm.codeTx = t.codeTx AND PAYEE = TRUE
AND c.NCLI = cm.NCLI
HAVING total > 5000;

-- 3b
SELECT c.NCLI, cm.NCOM, totalSansTx, (totalSansTx * TPS) tps, (totalSanstx * TVQ) as tvq, totalSansTx*(TPS+TVQ) as total
FROM CLIENT c, COMMANDE cm, TAXE t
WHERE c.NCLI = cm.NCLI AND cm.codeTx = t.codeTx
ORDER BY c.NCLI, cm.NCOM;

-- 3c
select QCOM 
