export function ConfirmDialog({ title, body, confirmLabel = 'Confirm', tone = 'default', onConfirm, onCancel }) {
  return (
    <div
      className="fixed inset-0 z-[60] grid place-items-center bg-neutral-950/40 p-4"
      role="dialog"
      aria-modal="true"
      onClick={onCancel}
    >
      <div
        className="w-full max-w-sm rounded-2xl border border-border bg-white p-6 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <h3 className="mb-1.5 font-medium">{title}</h3>
        <p className="mb-6 text-sm text-muted-foreground">{body}</p>

        <div className="flex justify-end gap-2">
          <button
            onClick={onCancel}
            className="rounded-lg border border-border px-4 py-2 text-sm transition hover:bg-muted"
          >
            Cancel
          </button>
          <button
            autoFocus
            onClick={onConfirm}
            className={
              tone === 'danger'
                ? 'rounded-lg bg-red-600 px-4 py-2 text-sm text-white transition hover:bg-red-500'
                : 'rounded-lg bg-neutral-900 px-4 py-2 text-sm text-white transition hover:bg-neutral-700'
            }
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  )
}
