--
-- This script creates the Airlock IAM default schema for MariaDB.
--
-- Please ensure that the database uses 'utf8mb4' character encoding and InnoDB as storage engine.
--

CREATE TABLE schema_metadata
(
    pk      TINYINT DEFAULT 1 PRIMARY KEY CHECK (pk = 1),
    version VARCHAR(10) COLLATE utf8mb4_nopad_bin NOT NULL
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
INSERT INTO schema_metadata (version)
VALUES ('8.7');

CREATE TABLE medusa_user
(
    -- General authentication information fields
    username                      VARCHAR(100)      NOT NULL,
    auth_method                   VARCHAR(50),
    next_auth_method              VARCHAR(50),
    auth_migration_date           DATETIME(6),
    locked                        INTEGER DEFAULT 0 NOT NULL,
    lock_reason                   VARCHAR(50),
    lock_date                     DATETIME(6),
    valid                         INTEGER DEFAULT 1 NOT NULL,
    not_valid_before              DATETIME(6),
    not_valid_after               DATETIME(6),

    -- Statistic data
    failed_logins                 INTEGER,
    failed_logins_before          INTEGER,
    failed_token_counts           TEXT,
    total_logins                  INTEGER,
    lat_succ_login                DATETIME(6),
    lat_succ_login2               DATETIME(6),
    lat_login_attempt             DATETIME(6),
    first_login                   DATETIME(6),
    unlock_attempts               INTEGER,
    lat_unlock_attempt            DATETIME(6),

    -- self-registration data
    self_registered               INTEGER DEFAULT 0 NOT NULL,
    self_registration_date        DATETIME(6),
    inactivity_reminder_sent_date DATETIME(6),
    channel_verification_resends  INTEGER,

    -- Role settings
    roles                         VARCHAR(1000),

    -- User context data
    salutation                    VARCHAR(50),
    givenname                     VARCHAR(50),
    surname                       VARCHAR(50),
    street                        VARCHAR(100),
    streetNumber                  VARCHAR(20),
    address2                      VARCHAR(100),
    zipcode                       VARCHAR(12),
    town                          VARCHAR(50),
    state                         VARCHAR(50),
    country                       VARCHAR(50),
    company                       VARCHAR(75),
    email                         VARCHAR(100),
    new_email                     VARCHAR(100),
    language                      VARCHAR(5) COLLATE utf8mb4_nopad_bin,
    birthdate                     DATE,
    disclaimer_tag                VARCHAR(1024),
    realm                         VARCHAR(50),

    -- Technical database fields
    rowVersionId                  INTEGER DEFAULT 0 NOT NULL,
    rowInsertDate                 DATETIME(6),
    rowInsertUser                 VARCHAR(20),
    rowUpdateDate                 DATETIME(6),
    rowUpdateUser                 VARCHAR(20),
    deleted                       INTEGER DEFAULT 0 NOT NULL,

    -- Password related fields
    pwd_hash                      VARCHAR(4000),
    pwd_chg_enf                   INTEGER DEFAULT 0 NOT NULL,
    pwd_lat_del                   DATETIME(6),
    pwd_lat_gen                   DATETIME(6),
    pwd_lat_chg                   DATETIME(6),
    pwd_next_chg                  DATETIME(6),
    pwd_order_new                 INTEGER DEFAULT 0 NOT NULL,
    pwd_order_user                VARCHAR(100),
    pwd_order_date                DATETIME(6),
    pwd_failed_resets             INTEGER DEFAULT 0 NOT NULL,

    -- MTAN (SMS) related fields (including IAK)
    mtan_number                   VARCHAR(25),
    mtan_del_date                 DATETIME(6),
    mtan_ass_date                 DATETIME(6),
    mtan_order_new                INTEGER DEFAULT 0 NOT NULL,
    mtan_order_user               VARCHAR(100),
    mtan_order_date               DATETIME(6),
    mtan_iak                      TEXT,

    -- Certificate related fields (including IAK and self registration)
    cert_subject_cn               VARCHAR(200),
    cert_x509_data                TEXT,
    cert_serial                   VARCHAR(20),
    cert_del_date                 DATETIME(6),
    cert_ass_date                 DATETIME(6),
    cert_order_new                INTEGER DEFAULT 0 NOT NULL,
    cert_order_user               VARCHAR(100),
    cert_order_date               DATETIME(6),
    cert_iak                      TEXT,

    -- OATH OTP related fields
    oathotp_data                  VARCHAR(200),
    oathotp_serial                VARCHAR(20),
    oathotp_del_date              DATETIME(6),
    oathotp_gen_date              DATETIME(6),
    oathotp_order_new             INTEGER DEFAULT 0 NOT NULL,
    oathotp_order_user            VARCHAR(100),
    oathotp_order_date            DATETIME(6),

    -- SecurID related fields
    securid_user                  VARCHAR(25),
    securid_serial                VARCHAR(20),
    securid_pin                   VARCHAR(20),

    -- Matrix cards (TAN lists) related fields
    matrix_current_list           BLOB,
    matrix_next_list              BLOB,
    matrix_del_date               DATETIME(6),
    matrix_gen_date               DATETIME(6),
    matrix_order_new              INTEGER DEFAULT 0 NOT NULL,
    matrix_order_user             VARCHAR(100),
    matrix_order_date             DATETIME(6),
    matrix_chal_open_since        DATETIME(6),
    matrix_open_chals             INTEGER DEFAULT 0 NOT NULL,

    -- Only one login possible
    last_gsid_date                DATETIME(6),
    last_gsid_value               VARCHAR(50),

    -- Secret questions features per user
    secret_questions_enabled      INTEGER DEFAULT 0 NOT NULL,

    CONSTRAINT pk_medusa_user PRIMARY KEY (username)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_nopad_ci;
CREATE INDEX ix_medusa_user_realm ON medusa_user (realm);

CREATE TABLE medusa_admin
(
    -- General authentication information fields
    username                     VARCHAR(100)      NOT NULL,
    locked                       INTEGER DEFAULT 0 NOT NULL,
    lock_reason                  VARCHAR(50),
    lock_date                    DATETIME(6),
    not_valid_before             DATETIME(6),
    not_valid_after              DATETIME(6),

    -- Statistic data
    failed_logins                INTEGER,
    failed_logins_before         INTEGER,
    failed_first_factor_attempts INTEGER,
    failed_stepup_attempts       INTEGER,
    total_logins                 INTEGER,
    lat_succ_login               DATETIME(6),
    lat_succ_login2              DATETIME(6),
    lat_login_attempt            DATETIME(6),
    first_login                  DATETIME(6),

    -- Role settings
    roles                        VARCHAR(1000),

    -- User context data
    givenname                    VARCHAR(50),
    surname                      VARCHAR(50),
    email                        VARCHAR(100),
    realm                        VARCHAR(50),

    -- Technical database fields
    rowVersionId                 INTEGER DEFAULT 0 NOT NULL,
    rowInsertDate                DATETIME(6),
    rowInsertUser                VARCHAR(20),
    rowUpdateDate                DATETIME(6),
    rowUpdateUser                VARCHAR(20),
    deleted                      INTEGER DEFAULT 0 NOT NULL,

    -- Password related fields
    pwd_hash                     VARCHAR(4000),
    pwd_chg_enf                  INTEGER DEFAULT 0 NOT NULL,
    pwd_lat_del                  DATETIME(6),
    pwd_lat_gen                  DATETIME(6),
    pwd_lat_chg                  DATETIME(6),
    pwd_next_chg                 DATETIME(6),
    pwd_order_new                INTEGER DEFAULT 0 NOT NULL,

    CONSTRAINT pk_medusa_admin PRIMARY KEY (username)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_nopad_ci;

CREATE TABLE medusa_maint_msg
(
    name             VARCHAR(255)      NOT NULL,
    system_available INTEGER DEFAULT 1 NOT NULL,
    active           INTEGER DEFAULT 1 NOT NULL,
    valid_from       DATETIME(6)       NOT NULL,
    valid_to         DATETIME(6)       NOT NULL,
    location         VARCHAR(50),
    -- Technical database fields
    rowVersionId     INTEGER DEFAULT 0 NOT NULL,
    rowInsertDate    DATETIME(6),
    rowInsertUser    VARCHAR(20),
    rowUpdateDate    DATETIME(6),
    rowUpdateUser    VARCHAR(20),
    deleted          INTEGER DEFAULT 0 NOT NULL,

    CONSTRAINT pk_medusa_maint_msg PRIMARY KEY (name)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_nopad_ci;

CREATE TABLE medusa_maint_msg_tnsl
(
    message_ref   VARCHAR(255)                         NOT NULL,
    language      VARCHAR(5) COLLATE utf8mb4_nopad_bin NOT NULL,
    message       VARCHAR(4000)                        NOT NULL,
    -- Technical database fields
    rowVersionId  INTEGER DEFAULT 0                    NOT NULL,
    rowInsertDate DATETIME(6),
    rowInsertUser VARCHAR(20),
    rowUpdateDate DATETIME(6),
    rowUpdateUser VARCHAR(20),
    deleted       INTEGER DEFAULT 0                    NOT NULL,

    CONSTRAINT pk_medusa_maint_msg_tnsl PRIMARY KEY (message_ref, language)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_nopad_ci;

CREATE TABLE token
(
    token_id                BIGINT            NOT NULL AUTO_INCREMENT,
    type                    VARCHAR(20),
    serial_id               VARCHAR(50),
    active                  TINYINT DEFAULT 0 NOT NULL,
    activation_date         BIGINT,
    obsoletes_token_id      BIGINT,
    validity_range_lower    BIGINT,
    validity_range_upper    BIGINT,
    generation_date         BIGINT,
    first_usage_date        BIGINT,
    latest_usage_date       BIGINT,
    total_usages            INTEGER DEFAULT 0 NOT NULL,
    token_data              TEXT,
    activates_token_id      BIGINT,
    tracking_id             TEXT,
    generic_data_element_1  TEXT,
    generic_data_element_2  TEXT,
    generic_data_element_3  TEXT,
    generic_data_element_4  TEXT,
    generic_data_element_5  TEXT,
    generic_data_element_6  TEXT,
    generic_data_element_7  TEXT,
    generic_data_element_8  TEXT,
    generic_data_element_9  TEXT,
    generic_data_element_10 TEXT,
    generic_data_element_11 TEXT,
    generic_data_element_12 TEXT,

    CONSTRAINT pk_token_id PRIMARY KEY (token_id)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_nopad_ci;
-- FOREIGN KEY indexes
CREATE INDEX obsoletes_token_id_idx
    ON token (obsoletes_token_id);
ALTER TABLE token
    ADD CONSTRAINT fk_obsoletes_token_id FOREIGN KEY (obsoletes_token_id) REFERENCES token (token_id);
CREATE INDEX activates_token_id_index
    ON token (activates_token_id);
ALTER TABLE token
    ADD CONSTRAINT fk_activates_token_id FOREIGN KEY (activates_token_id) REFERENCES token (token_id);
-- Additional indexes
CREATE INDEX idx_token_type_expiry
    ON token (type, validity_range_upper);
CREATE INDEX token_serial_id_index
    ON token (serial_id);
-- Supports the mTAN phone number user search of the adminapp (exact match on token_data).
-- Columns of type TEXT (like token_data) can only be indexed with a prefix; 40 characters fully cover normalized phone numbers.
CREATE INDEX token_data_idx
    ON token (token_data(40));
CREATE INDEX generic_data_element_1_idx
    ON token (generic_data_element_1(40));
CREATE INDEX generic_data_element_2_idx
    ON token (generic_data_element_2(40));
CREATE INDEX generic_data_element_3_idx
    ON token (generic_data_element_3(40));
CREATE INDEX generic_data_element_4_idx
    ON token (generic_data_element_4(40));
CREATE INDEX generic_data_element_6_idx
    ON token (generic_data_element_6(40));
CREATE INDEX generic_data_element_7_idx
    ON token (generic_data_element_7(40));

CREATE TABLE token_assignment
(
    ta_token_id               BIGINT            NOT NULL,
    ta_user                   VARCHAR(100)      NOT NULL,
    ta_assignment_date        BIGINT            NOT NULL,
    ta_assignment_user        VARCHAR(100)      NOT NULL,
    ta_order_new              TINYINT DEFAULT 0 NOT NULL,
    ta_order_new_date         BIGINT,
    ta_order_new_user         VARCHAR(100),
    ta_order_options          VARCHAR(250),
    ta_additional_information VARCHAR(250),
    ta_comment                TEXT,

    CONSTRAINT pk_ta_token_id_user PRIMARY KEY (ta_token_id, ta_user)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_nopad_ci;
-- FOREIGN KEY indexes
ALTER TABLE token_assignment
    ADD CONSTRAINT fk_ta_token_id FOREIGN KEY (ta_token_id) REFERENCES token (token_id) ON DELETE CASCADE;
-- Additional indexes
CREATE INDEX ta_index
    ON token_assignment (ta_user, ta_token_id);

CREATE TABLE login_history
(
    id                     INTEGER      NOT NULL AUTO_INCREMENT,
    username               VARCHAR(100) NOT NULL,
    login_timestamp        DATETIME(6)  NOT NULL,
    ip                     VARCHAR(45)  NOT NULL,
    header_user_agent      VARCHAR(512),
    header_accept_encoding VARCHAR(512),
    header_accept_language VARCHAR(512),
    geoloc_present         INTEGER      NOT NULL,
    geoloc_continent       CHAR(2),
    geoloc_country         CHAR(2),
    geoloc_subdivision     CHAR(3),
    geoloc_city            VARCHAR(256),
    geoloc_zip             VARCHAR(32),
    geoloc_timezone        VARCHAR(128),
    geoloc_latitude        VARCHAR(16),
    geoloc_longitude       VARCHAR(16),

    CONSTRAINT pk_login_history PRIMARY KEY (id)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_nopad_ci;
-- Additional indexes
CREATE INDEX login_history_idx
    ON login_history (username);

CREATE TABLE account_link
(
    link_id        INTEGER      NOT NULL AUTO_INCREMENT,
    username       VARCHAR(100) NOT NULL,
    provider_id    VARCHAR(20)  NOT NULL,
    account_sub    VARCHAR(255) NOT NULL,
    account_info   VARCHAR(255),
    established_at DATETIME(6)  NOT NULL,
    tenant_id      VARCHAR(50)  NOT NULL,

    CONSTRAINT pk_account_link PRIMARY KEY (link_id)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_nopad_ci;
-- Additional indexes
CREATE INDEX account_link_idx_username
    ON account_link (username, tenant_id);
CREATE INDEX account_link_idx_usr_prov
    ON account_link (username, provider_id, tenant_id);
CREATE UNIQUE INDEX account_link_idx_unique
    ON account_link (account_sub, provider_id, tenant_id);

CREATE TABLE subscription
(
    pk           INTEGER                               NOT NULL AUTO_INCREMENT,
    id           VARCHAR(36) COLLATE latin1_nopad_bin  NOT NULL,
    display_name VARCHAR(100)                          NOT NULL,
    tenant_id    VARCHAR(50) COLLATE utf8mb4_nopad_bin NOT NULL,

    CONSTRAINT pk_subscription PRIMARY KEY (pk)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- Additional indexes
CREATE UNIQUE INDEX subscription_id_idx_unique
    ON subscription (id);

CREATE TABLE principal
(
    pk              INTEGER           NOT NULL AUTO_INCREMENT,
    id              VARCHAR(36)       NOT NULL,
    display_name    VARCHAR(100)      NOT NULL,
    locked          INTEGER DEFAULT 0 NOT NULL,
    lock_reason     VARCHAR(100),
    lock_date       DATETIME(6),
    creation_date   DATETIME(6)       NOT NULL,
    tenant_id       VARCHAR(50)       NOT NULL,
    description     VARCHAR(100),
    label           VARCHAR(100),
    subscription_pk INTEGER,

    CONSTRAINT pk_principal PRIMARY KEY (pk)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_nopad_ci;
-- FOREIGN KEY indexes
CREATE INDEX subscription_idx
    ON principal (subscription_pk);
ALTER TABLE principal
    ADD CONSTRAINT fk_subscription_pk FOREIGN KEY (subscription_pk) REFERENCES subscription (pk);
-- Additional indexes
CREATE UNIQUE INDEX principal_id_idx_unique
    ON principal (id);
CREATE INDEX tenant_id_idx
    ON principal (tenant_id);

CREATE TABLE oauth2_attributes
(
    pk                         INTEGER     NOT NULL AUTO_INCREMENT,
    principal_pk               INTEGER     NOT NULL,
    authorization_server_id    VARCHAR(50) NOT NULL,
    client_id                  VARCHAR(50) NOT NULL,
    client_secret              VARCHAR(450),
    client_id_issued_at        DATETIME(6) NOT NULL,
    client_secret_expires_at   DATETIME(6),
    redirect_uris              TEXT,
    token_endpoint_auth_method VARCHAR(50),
    grant_types                VARCHAR(200),
    response_types             VARCHAR(50),
    client_name                VARCHAR(200),
    client_uri                 VARCHAR(200),
    logo_uri                   VARCHAR(200),
    scopes                     VARCHAR(200),
    contacts                   TEXT,
    tos_uri                    VARCHAR(200),
    policy_uri                 VARCHAR(200),
    jwks_uri                   VARCHAR(200),
    software_id                VARCHAR(50),
    software_version           VARCHAR(50),
    cert_issuer                VARCHAR(450),
    cert_subject               VARCHAR(450),
    tenant_id                  VARCHAR(50) NOT NULL,

    CONSTRAINT pk_oauth2_attributes PRIMARY KEY (pk)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_nopad_ci;
-- FOREIGN KEY indexes
CREATE UNIQUE INDEX oa2_attrs_principal_idx_unique
    ON oauth2_attributes (principal_pk);
ALTER TABLE oauth2_attributes
    ADD CONSTRAINT fk_oa_principal_pk FOREIGN KEY (principal_pk) REFERENCES principal (pk) ON DELETE CASCADE;
-- Additional indexes
CREATE UNIQUE INDEX oa2_attrs_as_cid_idx_unique
    ON oauth2_attributes (authorization_server_id, client_id, tenant_id);

CREATE TABLE oauth2_attribute_translation
(
    oauth2_attributes_pk INTEGER NOT NULL,
    attribute_name       VARCHAR(20),
    locale               VARCHAR(20),
    text                 VARCHAR(200)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_nopad_ci;
-- FOREIGN KEY indexes
CREATE INDEX oauth2_attributes_pk_idx
    ON oauth2_attribute_translation (oauth2_attributes_pk);
ALTER TABLE oauth2_attribute_translation
    ADD CONSTRAINT fk_oauth2_attributes_pk FOREIGN KEY (oauth2_attributes_pk) REFERENCES oauth2_attributes (pk) ON DELETE CASCADE;
-- Additional indexes
CREATE UNIQUE INDEX oauth2_translation_idx_unique
    ON oauth2_attribute_translation (oauth2_attributes_pk, attribute_name, locale);

CREATE TABLE oauth2_session
(
    pk     BIGINT                                NOT NULL AUTO_INCREMENT,
    id     VARCHAR(40) COLLATE utf8mb4_nopad_bin NOT NULL,
    claims TEXT COLLATE utf8mb4_general_nopad_ci,

    CONSTRAINT pk_oauth2_session PRIMARY KEY (pk)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- Additional indexes
CREATE UNIQUE INDEX ux_oauth2_session_id
    ON oauth2_session (id);

CREATE TABLE oauth2_session_attribute
(
    oauth2_session_pk BIGINT                                NOT NULL,
    name              VARCHAR(50) COLLATE utf8mb4_nopad_bin NOT NULL,
    content           VARCHAR(200)                          NOT NULL
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- FOREIGN KEY indexes
CREATE INDEX ix_osa_oauth2_session_pk
    ON oauth2_session_attribute (oauth2_session_pk);
ALTER TABLE oauth2_session_attribute
    ADD CONSTRAINT fk_oauth2_session_pk FOREIGN KEY (oauth2_session_pk) REFERENCES oauth2_session (pk) ON DELETE CASCADE;

CREATE TABLE client_cert_credential
(
    id           VARCHAR(36)                      NOT NULL,
    principal_pk INTEGER                          NOT NULL,
    serial       VARCHAR(50)                      NOT NULL,
    issuer       VARCHAR(450)                     NOT NULL,
    subject      VARCHAR(450)                     NOT NULL,
    not_before   DATETIME(6)                      NOT NULL,
    not_after    DATETIME(6)                      NOT NULL,
    certificate  TEXT                             NOT NULL,
    fingerprint  VARCHAR(200) COLLATE utf8mb4_bin NOT NULL,
    tenant_id    VARCHAR(50)                      NOT NULL
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_nopad_ci;
-- FOREIGN KEY indexes
CREATE INDEX principal_pk_idx
    ON client_cert_credential (principal_pk);
ALTER TABLE client_cert_credential
    ADD CONSTRAINT fk_ccc_principal_pk FOREIGN KEY (principal_pk) REFERENCES principal (pk) ON DELETE CASCADE;
-- Additional indexes
CREATE UNIQUE INDEX ccc_id_idx_unique
    ON client_cert_credential (id);
CREATE UNIQUE INDEX fingerprint_idx_unique
    ON client_cert_credential (fingerprint, tenant_id);
CREATE INDEX ccc_subject_idx
    ON client_cert_credential (subject);

CREATE TABLE airlock_2fa_user
(
    pk                  INTEGER                                NOT NULL AUTO_INCREMENT,
    iam_user_id         VARCHAR(100) COLLATE utf8mb4_nopad_bin NOT NULL,
    airlock_2fa_user_id VARCHAR(50) COLLATE latin1_nopad_bin   NOT NULL,
    tenant_id           VARCHAR(50) COLLATE utf8mb4_nopad_bin  NOT NULL,

    CONSTRAINT pk_airlock_2fa_user PRIMARY KEY (pk)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- Additional indexes
CREATE UNIQUE INDEX a2fa_iam_user_id_idx_unique
    ON airlock_2fa_user (iam_user_id, tenant_id);
CREATE UNIQUE INDEX a2fa_user_id_idx_unique
    ON airlock_2fa_user (airlock_2fa_user_id);

CREATE TABLE airlock_2fa_activation_letter
(
    pk                  INTEGER                                NOT NULL AUTO_INCREMENT,
    id                  VARCHAR(36) COLLATE latin1_nopad_bin   NOT NULL,
    activation_code     VARCHAR(750) COLLATE latin1_nopad_bin  NOT NULL,
    airlock_2fa_user_pk INTEGER                                NOT NULL,
    creator             VARCHAR(100) COLLATE utf8mb4_nopad_bin NOT NULL,

    CONSTRAINT pk_2fa_activation_letter PRIMARY KEY (pk)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- FOREIGN KEY indexes
CREATE INDEX fk_activation_letter_user_pk
    ON airlock_2fa_activation_letter (airlock_2fa_user_pk);
ALTER TABLE airlock_2fa_activation_letter
    ADD CONSTRAINT fk_activation_letter_user_pk FOREIGN KEY (airlock_2fa_user_pk) REFERENCES airlock_2fa_user (pk) ON DELETE CASCADE;
-- Additional indexes
CREATE UNIQUE INDEX a2fa_letter_id_idx_unique
    ON airlock_2fa_activation_letter (id);

CREATE TABLE airlock_2fa_activation_order
(
    id                  VARCHAR(36) COLLATE utf8mb4_nopad_bin  NOT NULL,
    airlock_2fa_user_pk INTEGER                                NOT NULL,
    creator             VARCHAR(100) COLLATE utf8mb4_nopad_bin NOT NULL,
    ordered_at          BIGINT                                 NOT NULL
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- FOREIGN KEY indexes
CREATE INDEX ix_a2fa_activ_order_user_pk
    ON airlock_2fa_activation_order (airlock_2fa_user_pk);
ALTER TABLE airlock_2fa_activation_order
    ADD CONSTRAINT fk_a2fa_activ_order_user_pk FOREIGN KEY (airlock_2fa_user_pk) REFERENCES airlock_2fa_user (pk) ON DELETE CASCADE;
-- Additional indexes
CREATE UNIQUE INDEX ux_a2fa_activ_order_id
    ON airlock_2fa_activation_order (id);

CREATE TABLE api_key
(
    id            VARCHAR(36) COLLATE latin1_nopad_bin  NOT NULL,
    principal_pk  INTEGER                               NOT NULL,
    fingerprint   VARCHAR(30) COLLATE latin1_nopad_bin  NOT NULL,
    secret        VARCHAR(450) COLLATE latin1_nopad_bin NOT NULL,
    description   VARCHAR(100),
    valid_from    DATETIME(6),
    valid_to      DATETIME(6),
    locked        INTEGER DEFAULT 0                     NOT NULL,
    creation_date DATETIME(6)                           NOT NULL,
    tenant_id     VARCHAR(50) COLLATE utf8mb4_nopad_bin NOT NULL
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- FOREIGN KEY indexes
CREATE INDEX fk_api_key_principal_pk
    ON api_key (principal_pk);
ALTER TABLE api_key
    ADD CONSTRAINT fk_api_key_principal_pk FOREIGN KEY (principal_pk) REFERENCES principal (pk) ON DELETE CASCADE;
-- Additional indexes
CREATE UNIQUE INDEX api_key_id_idx_unique
    ON api_key (id);
CREATE UNIQUE INDEX api_key_fp_idx_unique
    ON api_key (fingerprint, tenant_id);

CREATE TABLE plan_usage
(
    id              VARCHAR(36) COLLATE latin1_nopad_bin NOT NULL,
    subscription_pk INTEGER                              NOT NULL,
    name            VARCHAR(100)                         NOT NULL,
    rate_limit      INTEGER
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- FOREIGN KEY indexes
CREATE INDEX fk_plan_usage_subscription_pk
    ON plan_usage (subscription_pk);
ALTER TABLE plan_usage
    ADD CONSTRAINT fk_plan_usage_subscription_pk FOREIGN KEY (subscription_pk) REFERENCES subscription (pk) ON DELETE CASCADE;
-- Additional indexes
CREATE UNIQUE INDEX plan_usage_subscr_idx_unique
    ON plan_usage (name, subscription_pk);
CREATE UNIQUE INDEX plan_usage_id_idx_unique
    ON plan_usage (id);

CREATE TABLE last_selection
(
    last_selection_id INTEGER                               NOT NULL AUTO_INCREMENT,
    username          VARCHAR(100)                          NOT NULL,
    option_id         VARCHAR(50) COLLATE utf8mb4_nopad_bin NOT NULL,
    selected_at       DATETIME(6)                           NOT NULL,
    step_id           VARCHAR(50) COLLATE utf8mb4_nopad_bin NOT NULL,
    tenant_id         VARCHAR(50) COLLATE utf8mb4_nopad_bin NOT NULL,

    CONSTRAINT pk_last_selection PRIMARY KEY (last_selection_id)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- Additional indexes
CREATE UNIQUE INDEX ux_last_selection
    ON last_selection (username, tenant_id, step_id);

CREATE TABLE fido_user
(
    pk               BIGINT                                        NOT NULL AUTO_INCREMENT,
    iam_user_id      VARCHAR(100) COLLATE utf8mb4_general_nopad_ci NOT NULL,
    user_handle      VARCHAR(36) COLLATE utf8mb4_nopad_bin         NOT NULL,
    relying_party_id VARCHAR(255) COLLATE utf8mb4_general_nopad_ci NOT NULL,
    tenant_id        VARCHAR(50) COLLATE utf8mb4_nopad_bin         NOT NULL,

    CONSTRAINT pk_fido_user PRIMARY KEY (pk)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- Additional indexes
CREATE UNIQUE INDEX ux_fido_user_handle
    ON fido_user (user_handle);
CREATE UNIQUE INDEX ux_fido_iam_user_rpid
    ON fido_user (iam_user_id, relying_party_id, tenant_id);

CREATE TABLE fido_credential
(
    id                            VARCHAR(36) COLLATE utf8mb4_nopad_bin         NOT NULL,
    fido_user_pk                  BIGINT                                        NOT NULL,
    name                          VARCHAR(100) COLLATE utf8mb4_general_nopad_ci NOT NULL,
    display_name                  VARCHAR(100) COLLATE utf8mb4_general_nopad_ci NOT NULL,
    public_key_credential_id      BLOB                                          NOT NULL,
    public_key_credential_id_hash VARBINARY(64)                                 NOT NULL,
    public_key                    VARBINARY(1024)                               NOT NULL,
    signature_counter             BIGINT  DEFAULT 0                             NOT NULL,
    resident_requested            TINYINT                                       NOT NULL,
    attestation_object            BLOB                                          NOT NULL,
    registered_at                 BIGINT                                        NOT NULL,
    first_used_at                 BIGINT,
    last_used_at                  BIGINT,
    total_usages                  INTEGER DEFAULT 0                             NOT NULL,
    locked                        TINYINT                                       NOT NULL,
    transports                    VARCHAR(200) COLLATE utf8mb4_nopad_bin
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- FOREIGN KEY indexes
CREATE INDEX ix_fido_credential_user_pk
    ON fido_credential (fido_user_pk);
ALTER TABLE fido_credential
    ADD CONSTRAINT fk_fido_credential_user_pk FOREIGN KEY (fido_user_pk) REFERENCES fido_user (pk) ON DELETE CASCADE;
-- Additional indexes
CREATE UNIQUE INDEX ux_fido_cred_id
    ON fido_credential (id);
CREATE UNIQUE INDEX ux_fido_cred_id_hash
    ON fido_credential (public_key_credential_id_hash);

CREATE TABLE remember_me_token
(
    pk          BIGINT                                        NOT NULL AUTO_INCREMENT,
    id          VARCHAR(36) COLLATE utf8mb4_nopad_bin         NOT NULL,
    iam_user_id VARCHAR(100) COLLATE utf8mb4_general_nopad_ci NOT NULL,
    token_hash  VARBINARY(64)                                 NOT NULL,
    created_at  BIGINT                                        NOT NULL,
    renewed_at  BIGINT,
    tenant_id   VARCHAR(50) COLLATE utf8mb4_nopad_bin         NOT NULL,

    CONSTRAINT pk_remember_me_token PRIMARY KEY (pk)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- Additional indexes
CREATE INDEX ix_remember_me_iam_user_id ON remember_me_token (iam_user_id);
CREATE INDEX ix_remember_me_token_created_at ON remember_me_token (created_at, tenant_id);
CREATE INDEX ix_remember_me_token_renewed_at ON remember_me_token (renewed_at, tenant_id);
CREATE UNIQUE INDEX ux_remember_me_id ON remember_me_token (id, tenant_id);
CREATE UNIQUE INDEX ux_remember_me_token_hash ON remember_me_token (token_hash, tenant_id);

CREATE TABLE remember_me_request_metadata
(
    pk                      BIGINT                                NOT NULL AUTO_INCREMENT,
    remember_me_token_pk    BIGINT                                NOT NULL,
    request_type            TINYINT                               NOT NULL,
    request_ip              VARCHAR(45) COLLATE utf8mb4_nopad_bin NOT NULL,
    header_user_agent       VARCHAR(4000) COLLATE utf8mb4_general_nopad_ci,
    geolocation_continent   VARCHAR(2) COLLATE utf8mb4_general_nopad_ci,
    geolocation_country     VARCHAR(2) COLLATE utf8mb4_general_nopad_ci,
    geolocation_subdivision VARCHAR(3) COLLATE utf8mb4_general_nopad_ci,
    geolocation_city        VARCHAR(256) COLLATE utf8mb4_general_nopad_ci,
    geolocation_zip         VARCHAR(32) COLLATE utf8mb4_general_nopad_ci,
    geolocation_timezone    VARCHAR(128) COLLATE utf8mb4_general_nopad_ci,
    geolocation_latitude    VARCHAR(16) COLLATE utf8mb4_nopad_bin,
    geolocation_longitude   VARCHAR(16) COLLATE utf8mb4_nopad_bin,

    CONSTRAINT pk_remember_me_request_metadata PRIMARY KEY (pk)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- FOREIGN KEY indexes
ALTER TABLE remember_me_request_metadata
    ADD CONSTRAINT fk_remember_me_token_pk FOREIGN KEY (remember_me_token_pk) REFERENCES remember_me_token (pk) ON DELETE CASCADE;
-- Additional indexes
CREATE UNIQUE INDEX ux_remember_me_token_request_type ON remember_me_request_metadata (remember_me_token_pk, request_type);

CREATE TABLE flow_continuation_token
(
    pk                    BIGINT                                        NOT NULL AUTO_INCREMENT,
    token_hash            VARCHAR(86) COLLATE utf8mb4_nopad_bin         NOT NULL,
    user_id               VARCHAR(100) COLLATE utf8mb4_general_nopad_ci NOT NULL,
    target_flow_id        VARCHAR(30) COLLATE utf8mb4_nopad_bin         NOT NULL,
    created_at            BIGINT                                        NOT NULL,
    valid_until           BIGINT                                        NOT NULL,
    configuration_context VARCHAR(50) COLLATE utf8mb4_nopad_bin         NOT NULL,
    forward_url           VARCHAR(200) COLLATE utf8mb4_general_nopad_ci,
    tenant_id             VARCHAR(50) COLLATE utf8mb4_nopad_bin         NOT NULL,

    CONSTRAINT pk_flow_continuation_token PRIMARY KEY (pk)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- Additional indexes
CREATE UNIQUE INDEX ux_flow_continuation_token ON flow_continuation_token (token_hash);

CREATE TABLE user_trail_log
(
    pk                    BIGINT                                         NOT NULL AUTO_INCREMENT,
    created_at            BIGINT                                         NOT NULL,
    log_level             VARCHAR(8) COLLATE utf8mb4_nopad_bin           NOT NULL,
    session_id            VARCHAR(256) COLLATE utf8mb4_nopad_bin         NOT NULL,
    request_id            VARCHAR(256) COLLATE utf8mb4_nopad_bin         NOT NULL,
    configuration_context VARCHAR(50) COLLATE utf8mb4_nopad_bin          NOT NULL,
    client_ip             VARCHAR(45) COLLATE utf8mb4_general_nopad_ci   NOT NULL,
    target_id             VARCHAR(100) COLLATE utf8mb4_general_nopad_ci  NOT NULL,
    authentee_id          VARCHAR(100) COLLATE utf8mb4_general_nopad_ci  NOT NULL,
    authentee_provided_id VARCHAR(100) COLLATE utf8mb4_general_nopad_ci  NOT NULL,
    message               VARCHAR(4000) COLLATE utf8mb4_general_nopad_ci NOT NULL,
    tenant_id             VARCHAR(50) COLLATE utf8mb4_nopad_bin          NOT NULL,

    CONSTRAINT pk_user_trail_log PRIMARY KEY (pk)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- Additional indexes
CREATE INDEX ix_user_trail_log_target_id ON user_trail_log (target_id, created_at);
CREATE INDEX ix_user_trail_log_created_at ON user_trail_log (created_at);

CREATE TABLE device_usage
(
    user_id           VARCHAR(100) COLLATE utf8mb4_general_nopad_ci NOT NULL,
    device_type       VARCHAR(20) COLLATE utf8mb4_nopad_bin         NOT NULL,
    device_id         VARCHAR(50) COLLATE utf8mb4_nopad_bin         NOT NULL,
    total_usages      INTEGER                                       NOT NULL,
    first_usage_date  BIGINT                                        NOT NULL,
    latest_usage_date BIGINT                                        NOT NULL,
    tenant_id         VARCHAR(50) COLLATE utf8mb4_nopad_bin         NOT NULL
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;

-- Additional indexes
CREATE UNIQUE INDEX ux_device_usage ON device_usage (device_id, user_id, device_type, tenant_id);

CREATE TABLE accepted_sso_tickets
(
    ticket_id  VARCHAR(100) COLLATE utf8mb4_nopad_bin NOT NULL,
    expires_at BIGINT                                 NOT NULL,
    tenant_id  VARCHAR(50) COLLATE utf8mb4_nopad_bin  NOT NULL
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- Additional indexes
CREATE UNIQUE INDEX ux_accepted_sso_tickets ON accepted_sso_tickets (ticket_id, tenant_id);
CREATE INDEX ix_accepted_sso_tickets_expires_at ON accepted_sso_tickets (expires_at);

CREATE TABLE oauth2_consent
(
    id                      VARCHAR(36) COLLATE utf8mb4_nopad_bin         NOT NULL,
    user_id                 VARCHAR(100) COLLATE utf8mb4_general_nopad_ci NOT NULL,
    authorization_server_id VARCHAR(50) COLLATE utf8mb4_nopad_bin         NOT NULL,
    client_id               VARCHAR(50) COLLATE utf8mb4_nopad_bin         NOT NULL,
    scope_name              VARCHAR(50) COLLATE utf8mb4_nopad_bin         NOT NULL,
    status                  VARCHAR(20) COLLATE utf8mb4_nopad_bin         NOT NULL,
    updated_at              BIGINT                                        NOT NULL,
    tenant_id               VARCHAR(50) COLLATE utf8mb4_nopad_bin         NOT NULL
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- Additional indexes
CREATE UNIQUE INDEX ux_oauth2_consent_id ON oauth2_consent (id);
CREATE INDEX ix_oauth2_consent_user_as_client ON oauth2_consent (user_id, authorization_server_id, client_id);

CREATE TABLE oauth2_par_request
(
    request_uri_reference   VARCHAR(50) COLLATE utf8mb4_nopad_bin NOT NULL,
    authorization_server_id VARCHAR(50) COLLATE utf8mb4_nopad_bin NOT NULL,
    client_id               VARCHAR(50) COLLATE utf8mb4_nopad_bin NOT NULL,
    query_string            TEXT COLLATE utf8mb4_general_nopad_ci NOT NULL,
    valid_until             BIGINT                                NOT NULL,
    tenant_id               VARCHAR(50) COLLATE utf8mb4_nopad_bin NOT NULL
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- Additional indexes
CREATE UNIQUE INDEX ux_oauth2_par_request_uri ON oauth2_par_request (request_uri_reference);
CREATE INDEX ix_oauth2_par_request_valid_until ON oauth2_par_request (valid_until ASC);


CREATE TABLE oauth2_accepted_client_assertions
(
    jti        VARCHAR(100) COLLATE utf8mb4_nopad_bin NOT NULL,
    expires_at BIGINT                                 NOT NULL,
    tenant_id  VARCHAR(50) COLLATE utf8mb4_nopad_bin  NOT NULL
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- Additional indexes
CREATE UNIQUE INDEX ux_oauth2_accepted_client_assertions ON oauth2_accepted_client_assertions (jti);
CREATE INDEX ix_oauth2_accepted_client_assertions_expires_at ON oauth2_accepted_client_assertions (expires_at ASC);

CREATE TABLE verifiable_credential
(
    credential_id VARCHAR(50) COLLATE utf8mb4_nopad_bin         NOT NULL,
    user_id       VARCHAR(100) COLLATE utf8mb4_general_nopad_ci NOT NULL,
    tenant_id     VARCHAR(50) COLLATE utf8mb4_nopad_bin         NOT NULL,

    CONSTRAINT pk_verifiable_credential PRIMARY KEY (credential_id)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;
-- Additional indexes
CREATE INDEX ix_verifiable_credential_user_id ON verifiable_credential (user_id);

CREATE TABLE event_outbox
(
    event_id    VARCHAR(36) COLLATE utf8mb4_nopad_bin  NOT NULL,
    event_type  VARCHAR(255) COLLATE utf8mb4_nopad_bin NOT NULL,
    payload     TEXT COLLATE utf8mb4_general_nopad_ci  NOT NULL,
    created_at  BIGINT                                 NOT NULL,
    tie_breaker INTEGER                                NOT NULL,
    tenant_id   VARCHAR(50) COLLATE utf8mb4_nopad_bin  NOT NULL,

    CONSTRAINT pk_event_outbox PRIMARY KEY (event_id)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;

CREATE INDEX idx_event_outbox ON event_outbox (tenant_id, created_at, tie_breaker);

CREATE TABLE realm_role
(
    pk        BIGINT                                 NOT NULL AUTO_INCREMENT,
    name      VARCHAR(100) COLLATE utf8mb4_nopad_bin NOT NULL,
    parent_pk BIGINT,

    CONSTRAINT pk_realm_role PRIMARY KEY (pk)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;

CREATE UNIQUE INDEX ux_realm_role_name ON realm_role (name);
ALTER TABLE realm_role
    ADD CONSTRAINT fk_realm_role_parent_pk FOREIGN KEY (parent_pk) REFERENCES realm_role (pk);

CREATE TABLE realm_delegation
(
    id            VARCHAR(36) COLLATE utf8mb4_nopad_bin NOT NULL,
    realm_role_pk BIGINT                                NOT NULL,
    realm         VARCHAR(50) COLLATE utf8mb4_nopad_bin NOT NULL,
    permissions   TEXT COLLATE utf8mb4_general_nopad_ci NOT NULL,

    CONSTRAINT pk_realm_delegation PRIMARY KEY (id)
) CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_520_nopad_ci;

CREATE UNIQUE INDEX ux_realm_delegation_role_realm ON realm_delegation (realm, realm_role_pk);
ALTER TABLE realm_delegation
    ADD CONSTRAINT fk_realm_delegation_realm_role FOREIGN KEY (realm_role_pk) REFERENCES realm_role (pk);
