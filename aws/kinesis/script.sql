-- ####### Current version is working
CREATE OR REPLACE STREAM "TOP_VIEWS_BOOKS" (ISBN VARCHAR(16), MOST_FREQUENT_VALUES BIGINT);
CREATE OR REPLACE PUMP "TOP_VIEWS_BOOKS_PUMP" AS INSERT INTO "TOP_VIEWS_BOOKS"
SELECT STREAM *
        FROM TABLE (TOP_K_ITEMS_TUMBLING(CURSOR(SELECT STREAM * FROM "SOURCE_SQL_STREAM_001"),'ISBN',10,60));
CREATE OR REPLACE STREAM "TRIGGER_TOP_VIEWS_100" (ISBN VARCHAR(16), HITS BIGINT);
CREATE OR REPLACE PUMP "TRIGGER_TOP_VIEWS_100_PUMP" AS INSERT INTO "TRIGGER_TOP_VIEWS_100"
SELECT STREAM ISBN, HITS
FROM (SELECT ISBN, MOST_FREQUENT_VALUES as HITS FROM "TOP_VIEWS_BOOKS")
WHERE HITS>=100;


