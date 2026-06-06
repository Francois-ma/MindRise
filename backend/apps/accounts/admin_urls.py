from django.urls import path

from .views import ApprovePractitionerView, DeactivatePractitionerView, PendingPractitionerListView

urlpatterns = [
    path("practitioners/pending/", PendingPractitionerListView.as_view(), name="admin-practitioner-pending"),
    path("practitioners/<int:pk>/approve/", ApprovePractitionerView.as_view(), name="admin-practitioner-approve"),
    path(
        "practitioners/<int:pk>/deactivate/",
        DeactivatePractitionerView.as_view(),
        name="admin-practitioner-deactivate",
    ),
]