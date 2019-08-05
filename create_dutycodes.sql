DROP TABLE IF EXISTS DutyCodes;

-- next

CREATE TABLE DutyCodes (
	DutyRoot VARCHAR(2),
	DutySuffix VARCHAR(1),
	Description VARCHAR(100)
);

-- next

CREATE INDEX idx_DutyCodes ON DutyCodes (
	DutyRoot,
	DutySuffix,
	Description
);
