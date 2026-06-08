     1|#include "my_application.h"
     2|
     3|#include <flutter_linux/flutter_linux.h>
     4|#ifdef GDK_WINDOWING_X11
     5|#include <gdk/gdkx.h>
     6|#endif
     7|
     8|#include "flutter/generated_plugin_registrant.h"
     9|
    10|struct _MyApplication {
    11|  GtkApplication parent_instance;
    12|  char** dart_entrypoint_arguments;
    13|};
    14|
    15|G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)
    16|
    17|// Implements GApplication::activate.
    18|static void my_application_activate(GApplication* application) {
    19|  MyApplication* self = MY_APPLICATION(application);
    20|  GtkWindow* window =
    21|      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
    22|
    23|  // Use a header bar when running in GNOME as this is the common style used
    24|  // by applications and is the setup most users will be using (e.g. Ubuntu
    25|  // desktop).
    26|  // If running on X and not using GNOME then just use a traditional title bar
    27|  // in case the window manager does more exotic layout, e.g. tiling.
    28|  // If running on Wayland assume the header bar will work (may need changing
    29|  // if future cases occur).
    30|  gboolean use_header_bar = TRUE;
    31|#ifdef GDK_WINDOWING_X11
    32|  GdkScreen* screen = gtk_window_get_screen(window);
    33|  if (GDK_IS_X11_SCREEN(screen)) {
    34|    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    35|    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
    36|      use_header_bar = FALSE;
    37|    }
    38|  }
    39|#endif
    40|  if (use_header_bar) {
    41|    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    42|    gtk_widget_show(GTK_WIDGET(header_bar));
    43|    gtk_header_bar_set_title(header_bar, "GluCare");
    44|    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    45|    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
    46|  } else {
    47|    gtk_window_set_title(window, "GluCare");
    48|  }
    49|
    50|  gtk_window_set_default_size(window, 1280, 720);
    51|  gtk_widget_show(GTK_WIDGET(window));
    52|
    53|  g_autoptr(FlDartProject) project = fl_dart_project_new();
    54|  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);
    55|
    56|  FlView* view = fl_view_new(project);
    57|  gtk_widget_show(GTK_WIDGET(view));
    58|  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));
    59|
    60|  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
    61|
    62|  gtk_widget_grab_focus(GTK_WIDGET(view));
    63|}
    64|
    65|// Implements GApplication::local_command_line.
    66|static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
    67|  MyApplication* self = MY_APPLICATION(application);
    68|  // Strip out the first argument as it is the binary name.
    69|  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);
    70|
    71|  g_autoptr(GError) error = nullptr;
    72|  if (!g_application_register(application, nullptr, &error)) {
    73|     g_warning("Failed to register: %s", error->message);
    74|     *exit_status = 1;
    75|     return TRUE;
    76|  }
    77|
    78|  g_application_activate(application);
    79|  *exit_status = 0;
    80|
    81|  return TRUE;
    82|}
    83|
    84|// Implements GApplication::startup.
    85|static void my_application_startup(GApplication* application) {
    86|  //MyApplication* self = MY_APPLICATION(object);
    87|
    88|  // Perform any actions required at application startup.
    89|
    90|  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
    91|}
    92|
    93|// Implements GApplication::shutdown.
    94|static void my_application_shutdown(GApplication* application) {
    95|  //MyApplication* self = MY_APPLICATION(object);
    96|
    97|  // Perform any actions required at application shutdown.
    98|
    99|  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
   100|}
   101|
   102|// Implements GObject::dispose.
   103|static void my_application_dispose(GObject* object) {
   104|  MyApplication* self = MY_APPLICATION(object);
   105|  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
   106|  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
   107|}
   108|
   109|static void my_application_class_init(MyApplicationClass* klass) {
   110|  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
   111|  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
   112|  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
   113|  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
   114|  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
   115|}
   116|
   117|static void my_application_init(MyApplication* self) {}
   118|
   119|MyApplication* my_application_new() {
   120|  // Set the program name to the application ID, which helps various systems
   121|  // like GTK and desktop environments map this running application to its
   122|  // corresponding .desktop file. This ensures better integration by allowing
   123|  // the application to be recognized beyond its binary name.
   124|  g_set_prgname(APPLICATION_ID);
   125|
   126|  return MY_APPLICATION(g_object_new(my_application_get_type(),
   127|                                     "application-id", APPLICATION_ID,
   128|                                     "flags", G_APPLICATION_NON_UNIQUE,
   129|                                     nullptr));
   130|}
   131|