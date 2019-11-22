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
select NPRO, QSTOCK
FROM PRODUIT
WHERE QSTOCK < qMin;

-- 3d

-- 3e

-- 3f 
select c.NCLI, nom, NCOM, (totalSansTx+(totalSansTx*(TPS+TVQ))) as total
FROM CLIENT c LEFT JOIN COMMANDE cm on c.NCLI = cm.NCLI, TAXE t;


-- 5
    --a) La commande 99999 n'existe pas erreur de clé étrangère, insérer dans une commande existante ex: 30178
    --b) Duplicata de la clé primaire, changer la clé primaire F011 pour une non existante ex: G011
    --c) Ne peut pas supprimer le parent avant l'enfant (DETAIL a encore des data), faire un déclencheur afin d'assurer la propagation de la suppression de COMMANDE à DETAIL

-- 6

    -- Sur delete d'une commande non payée
    DELIMITER |
    CREATE TRIGGER suppCommande BEFORE DELETE
    ON COMMANDE FOR EACH ROW
        BEGIN
            IF(old.payee = 0)
                UPDATE CLIENT
                    SET COMPTE -= (old.totalSansTx + old.totalSansTx*(TPS+TVQ))
                    FROM TAXE t
                    WHERE old.codeTx = t.codeTx
                    AND old.NCLI = CLIENT.NCLI;
            END IF;
        END;
    END |
    DELIMITER ;

    -- Sur UPDATE totalSansTx
    DELIMITER |
    CREATE TRIGGER updateTotal AFTER UPDATE
    ON COMMANDE FOR EACH ROW
        BEGIN
            IF(old.payee = 0)
                UPDATE CLIENT
                    SET COMPTE -= (old.totalSansTx + old.totalSansTx*(TPS+TVQ))
                    FROM TAXE t
                    WHERE old.codeTx = t.codeTx
                    AND old.NCLI = CLIENT.NCLI;
            END IF;
            IF (new.payee = 0)
                UPDATE CLIENT
                        SET COMPTE += (new.totalSansTx + new.totalSansTx*(TPS+TVQ))
                        FROM TAXE t
                        WHERE new.codeTx = t.codeTx
                        AND new.NCLI = CLIENT.NCLI;
            END IF;
        END;
    END |
    DELIMITER ;


    -- Sur UPDATE boolean payee inutile car gérée dans le trigger du dessus
   /* DELIMITER |
    CREATE TRIGGER updatePayee AFTER UPDATE
    ON COMMANDE FOR EACH ROW
        BEGIN
            IF(old.payee = 0 AND new.payee = 1) -- pour s'assurer qu'une commande passe de non payée a payée
                UPDATE CLIENT
                    SET COMPTE = COMPTE - old.totalSansTx + old.totalSansTx*(TPS+TVQ)
                    FROM TAXE t
                    WHERE old.codeTx = t.codeTx
                    AND old.NCLI = CLIENT.NCLI;
            END IF;
        END;
    END |
    DELIMITER ; */
