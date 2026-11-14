# Third-party notices and scope

[MIT](LICENSE), Copyright (c) 2026 AndyPandi, covers this project's independently authored deployment code, tests and documentation. It does not relicense downloaded software, container contents, referenced documentation, trademarks or prior third-party material in Git history. Compose is independently authored; see [research](docs/research/upstream-compose.md).

Dependencies are downloaded separately, not vendored here. A container is an aggregation of components, not a single blanket license. Preserve and review notices from the exact artifacts you redistribute:

- Mattermost official Team compiled distribution: [v11.7.0 MIT compiled license](https://github.com/mattermost/mattermost/blob/v11.7.0/server/build/MIT-COMPILED-LICENSE.md). Server source is separately AGPLv3/commercial with exceptions; [version-specific research](docs/research/team-edition-license.md). Container OS and bundled dependencies retain their licenses. Enterprise/Entry terms are not Team terms.
- PostgreSQL: [PostgreSQL License](https://www.postgresql.org/about/licence/); official container packaging [docker-library/postgres](https://github.com/docker-library/postgres) has its own license and Alpine/bundled component notices.
- Docker Engine/Moby and Compose: [Moby Apache-2.0](https://github.com/moby/moby/blob/master/LICENSE), [Compose Apache-2.0](https://github.com/docker/compose/blob/main/LICENSE); containerd and other RPM dependencies retain their own notices. This stack does not distribute Docker Desktop or grant rights under its separate terms.
- OCI Terraform provider: [oracle/terraform-provider-oci MPL-2.0](https://github.com/oracle/terraform-provider-oci/blob/master/LICENSE). Terraform CLI releases have separate HashiCorp terms; our MIT license does not cover them.
- Oracle Linux RPMs and Alpine packages have package-specific licenses. Oracle Cloud service and account terms also remain applicable.
- Oracle Resource Manager documentation is a reference, not licensed here: [schema documentation](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/terraformconfigresourcemanager_topic-schema.htm). The previously copied schema fixture was removed because redistribution permission was unresolved; project tests now assert our own implementation contract. Earlier commits still contain the fixture; removal from HEAD is not history removal or a legal clearance.

Oracle, Mattermost, Docker and other names/logos remain their owners' trademarks. No affiliation, endorsement or trademark license is implied. Links and summaries are not a legal opinion or a guarantee of complete third-party compliance.
