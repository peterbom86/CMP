using System;

namespace Api.Domain.Base
{
    public abstract class Entity
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        /// <summary>Identifier the tenant that owns this entity</summary>
        public Guid TenantId { get; set; }

        public static readonly Guid Tenant1Id = new Guid("5C60F693-BEF5-E011-A485-80EE7300C695");
    }
}