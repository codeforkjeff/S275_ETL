DROP TABLE IF EXISTS duty_codes;

-- next

CREATE TABLE duty_codes (
	DutyRoot VARCHAR(2),
	DutySuffix VARCHAR(1),
	Description VARCHAR(100)
);

-- next

CREATE INDEX idx_duty_codes ON duty_codes (
	DutyRoot,
	DutySuffix,
	Description
);
