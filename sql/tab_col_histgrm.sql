ACCEPT C CHAR PROMPT 'Enter column name (C): ';
ACCEPT T CHAR PROMPT 'Enter table name (T): ';

SELECT
  wb,
  cnt,
  TO_CHAR(ROUND(100 * cnt / (MAX(cnt) OVER ()), 2), '999.00') AS rat,
  RPAD('*', 40 * cnt / (MAX(cnt) OVER ()), '*') AS hist
FROM
  (
    SELECT
      wb,
      COUNT(*) AS cnt
    FROM
      (
        SELECT
          WIDTH_BUCKET(r, 0, (SELECT COUNT(DISTINCT &C) FROM &T) + 1, 255) AS wb
        FROM
          (
            SELECT
              DENSE_RANK() OVER (ORDER BY &C) AS r
            FROM
              &T
          )
      )
    GROUP BY
      wb
  )
ORDER BY
  wb;
