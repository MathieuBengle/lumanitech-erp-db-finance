# Migration Checklist

Use this checklist when creating and applying migrations.

## Before Creating Migration

- [ ] Reviewed current schema and existing migrations
- [ ] Identified the next version number
- [ ] Planned the changes (what tables/columns/indexes)
- [ ] Considered backward compatibility
- [ ] Identified potential data issues

## Creating Migration File

- [ ] Named file correctly: `V###__description.sql`
- [ ] Added header comment with:
  - [ ] Migration version
  - [ ] Description
  - [ ] Date
  - [ ] Author
- [ ] Started with `USE lumanitech_erp_finance;`
- [ ] Used `IF NOT EXISTS` or `IF EXISTS` where appropriate
- [ ] Added appropriate indexes
- [ ] Included foreign key constraints if needed
- [ ] Added comments for complex logic
- [ ] Used consistent formatting

## Testing Migration

- [ ] Applied migration to local development database
- [ ] Verified tables/columns created correctly
- [ ] Checked indexes were created
- [ ] Tested foreign key constraints
- [ ] Verified data integrity
- [ ] Tested with seed data
- [ ] Checked migration tracking table updated
- [ ] Measured execution time for large changes
- [ ] Rolled back manually and retested (if possible)

## Code Review

- [ ] Ran validation script: `./scripts/validate.sh`
- [ ] Reviewed SQL syntax
- [ ] Checked naming conventions
- [ ] Verified security (no hardcoded secrets)
- [ ] Documented any special requirements
- [ ] Reviewed impact on existing queries
- [ ] Considered performance implications

## Before Committing

- [ ] All tests passed
- [ ] Documentation updated if needed
- [ ] Migration file in correct directory
- [ ] No sensitive data in migration
- [ ] Git diff reviewed
- [ ] Commit message is descriptive

## Pre-Deployment

- [ ] Migration tested in development environment
- [ ] Migration tested in staging environment
- [ ] Backup strategy confirmed
- [ ] Rollback plan documented (manual steps)
- [ ] Stakeholders notified
- [ ] Maintenance window scheduled (if needed)
- [ ] Execution time estimated
- [ ] Impact analysis completed

## During Deployment

- [ ] Database backup taken
- [ ] Migration script reviewed one final time
- [ ] Applied to production
- [ ] Migration tracking verified
- [ ] Execution time logged
- [ ] No errors in logs
- [ ] API functionality verified
- [ ] Monitoring checked

## Post-Deployment

- [ ] Migration marked as deployed
- [ ] Documentation updated
- [ ] Team notified of completion
- [ ] Any issues documented
- [ ] Performance monitored
- [ ] Backup verified

## Rollback (if needed)

- [ ] Issue identified and documented
- [ ] Rollback plan executed
- [ ] Database restored (if necessary)
- [ ] Root cause analysis started
- [ ] Fix planned as new migration
- [ ] Stakeholders notified

---

**Note**: Keep this checklist handy when working on migrations. Not all items apply to every migration, but they serve as a comprehensive guide.
