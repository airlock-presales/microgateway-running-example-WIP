/*
    Demo credentials:
      administrator: admin / Start123!
      OIDC users:    user1, user2 / Start123!
*/

DELETE
FROM medusa_admin
WHERE username = 'admin';

INSERT INTO medusa_admin (username,
                          givenname,
                          surname,
                          roles,
                          pwd_hash,
                          pwd_chg_enf)
VALUES ('admin',
        'IAM',
        'Administrator',
        'superadmin',
        'MedusaPwdHistoryAAAARzEzMTA3MnyD5V6qY+K/E3IdbsdJW+4ZzIC5T7lWG/qOpmEs2ZzTPW+GmftHC1Uvu9nwjUGS/gUXag0mQwDKRwQKchQO/uHYAAAARjE2Mzg0fF1jjOhya0ZuJ5OrHXgSXznOBBLl6eJ70PTdFYerSYPwgrlK1uq6UCzc5cvN8t1xtgc+YBQO8UgWBYhzDgpkQGM=',
        0
       );

DELETE
FROM medusa_user
WHERE username = 'user1';

INSERT INTO medusa_user (username,
                         givenname,
                         surname,
                         email,
                         pwd_hash,
                         pwd_chg_enf)
VALUES ('user1',
        'Demo',
        'User',
        'user1@example.org',
        'MedusaPwdHistoryAAAARzEzMTA3Mnz2sOwejQ1ET7uLhtNhVwe31xltFpZQ4xCACKbTRYIlI3YYGHC7nJBdHiMaeqO/O9u0UKNgxHOQJi0NJYlKFmqYAAAARzEzMTA3MnwS1Hxtzrow5mI4pqnB1T5DDAlR6nn4hfWMLvLumIL6RayioQKCKvZvzaOB+6WSRf+2Ne2ObH2h8iv8CwDImOiRAAAARzEzMTA3MnzQiTnl+ssbA2ka2oJ4jHF+BwbvunzQkM6rAWN3XZyLbGd/1vz7HAe8uxP7aoa7Tmuo3piph/p9byd/uQflUQyZ',
        0
       );

DELETE
FROM medusa_user
WHERE username = 'user2';

INSERT INTO medusa_user (username,
                         givenname,
                         surname,
                         email,
                         pwd_hash,
                         pwd_chg_enf)
VALUES ('user2',
        'Demo',
        'User',
        'user2@airlock.com',
        'MedusaPwdHistoryAAAARzEzMTA3Mnz2sOwejQ1ET7uLhtNhVwe31xltFpZQ4xCACKbTRYIlI3YYGHC7nJBdHiMaeqO/O9u0UKNgxHOQJi0NJYlKFmqYAAAARzEzMTA3MnwS1Hxtzrow5mI4pqnB1T5DDAlR6nn4hfWMLvLumIL6RayioQKCKvZvzaOB+6WSRf+2Ne2ObH2h8iv8CwDImOiRAAAARzEzMTA3MnzQiTnl+ssbA2ka2oJ4jHF+BwbvunzQkM6rAWN3XZyLbGd/1vz7HAe8uxP7aoa7Tmuo3piph/p9byd/uQflUQyZ',
        0
       );
